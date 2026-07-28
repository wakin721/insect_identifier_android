import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insect_identifier/controllers/app_controller.dart';
import 'package:insect_identifier/models/model_variant.dart';
import 'package:insect_identifier/models/recognition_prediction.dart';
import 'package:insect_identifier/models/recognition_record.dart';
import 'package:insect_identifier/repositories/history_repository.dart';
import 'package:insect_identifier/repositories/taxonomy_repository.dart';
import 'package:insect_identifier/services/insect_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('concurrent model preparation reuses a single load', () async {
    final classifier = _ControllableClassifier();
    final controller = AppController(
      taxonomy: await TaxonomyRepository.loadFromAssets(),
      historyRepository: _MemoryHistoryRepository(),
      classifierFactory: (_) => classifier,
    );

    final firstPreparation = controller.prepareModel();
    final secondPreparation = controller.prepareModel();

    expect(identical(firstPreparation, secondPreparation), isTrue);
    expect(classifier.loadCalls, 1);
    expect(controller.modelState, ModelRuntimeState.loading);

    classifier.completeLoad();
    await Future.wait(<Future<void>>[firstPreparation, secondPreparation]);

    expect(classifier.isLoaded, isTrue);
    expect(controller.modelState, ModelRuntimeState.ready);
    controller.dispose();
  });

  test('switching model disposes the previous classifier', () async {
    final classifiers = <ModelVariant, _TrackingClassifier>{};
    final controller = AppController(
      taxonomy: await TaxonomyRepository.loadFromAssets(),
      historyRepository: _MemoryHistoryRepository(),
      classifierFactory: (variant) {
        return classifiers.putIfAbsent(
          variant,
          _TrackingClassifier.new,
        );
      },
    );

    expect(controller.modelVariant, ModelVariant.fp32);
    await controller.switchModelVariant(ModelVariant.w8a16);

    expect(controller.modelVariant, ModelVariant.w8a16);
    expect(controller.modelState, ModelRuntimeState.idle);
    expect(classifiers[ModelVariant.fp32]!.disposeCalls, 1);
    expect(classifiers[ModelVariant.w8a16]!.disposeCalls, 0);
    controller.dispose();
  });
}

class _ControllableClassifier implements InsectClassifier {
  final Completer<void> _loadCompleter = Completer<void>();

  int loadCalls = 0;
  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load() async {
    loadCalls += 1;
    await _loadCompleter.future;
    _loaded = true;
  }

  void completeLoad() {
    _loadCompleter.complete();
  }

  @override
  Future<List<RecognitionPrediction>> classify(Uint8List imageBytes) async {
    await load();
    return const <RecognitionPrediction>[];
  }

  @override
  Future<void> dispose() async {}
}

class _MemoryHistoryRepository implements HistoryRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<void> delete(RecognitionRecord record) async {}

  @override
  Future<List<RecognitionRecord>> loadAll() async {
    return const <RecognitionRecord>[];
  }

  @override
  Future<RecognitionRecord> save({
    required Uint8List imageBytes,
    required List<RecognitionPrediction> predictions,
  }) {
    throw UnimplementedError();
  }
}

class _TrackingClassifier implements InsectClassifier {
  int disposeCalls = 0;

  @override
  bool get isLoaded => false;

  @override
  Future<List<RecognitionPrediction>> classify(Uint8List imageBytes) async {
    return const <RecognitionPrediction>[];
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }

  @override
  Future<void> load() async {}
}
