import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insect_identifier/controllers/app_controller.dart';
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
      classifier: classifier,
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
