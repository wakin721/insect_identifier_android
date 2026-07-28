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
      classifierFactory: (_, _) => classifier,
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
      classifierFactory: (variant, _) {
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

  test('switching GPU preference recreates and disposes classifier', () async {
    final classifiers = <_TrackingClassifier>[];
    final configurations = <(ModelVariant, bool)>[];
    final controller = AppController(
      taxonomy: await TaxonomyRepository.loadFromAssets(),
      historyRepository: _MemoryHistoryRepository(),
      classifierFactory: (variant, useGpu) {
        configurations.add((variant, useGpu));
        final classifier = _TrackingClassifier();
        classifiers.add(classifier);
        return classifier;
      },
    );

    expect(controller.useGpu, isTrue);
    await controller.switchUseGpu(false);

    expect(controller.modelVariant, ModelVariant.fp32);
    expect(controller.useGpu, isFalse);
    expect(
      configurations,
      <(ModelVariant, bool)>[
        (ModelVariant.fp32, true),
        (ModelVariant.fp32, false),
      ],
    );
    expect(classifiers.first.disposeCalls, 1);
    expect(classifiers.last.disposeCalls, 0);
    controller.dispose();
  });

  test('switching configuration does not wait for a stuck preparation',
      () async {
    final stuckClassifier = _ControllableClassifier();
    final replacementClassifier = _TrackingClassifier();
    var factoryCalls = 0;
    final controller = AppController(
      taxonomy: await TaxonomyRepository.loadFromAssets(),
      historyRepository: _MemoryHistoryRepository(),
      classifierFactory: (_, _) {
        factoryCalls += 1;
        return factoryCalls == 1
            ? stuckClassifier
            : replacementClassifier;
      },
    );

    final stuckPreparation = controller.prepareModel();
    expect(controller.modelState, ModelRuntimeState.loading);

    await controller
        .switchInferenceConfiguration(
          modelVariant: ModelVariant.w8a16,
          useGpu: false,
        )
        .timeout(const Duration(milliseconds: 200));

    expect(controller.modelVariant, ModelVariant.w8a16);
    expect(controller.useGpu, isFalse);
    expect(controller.modelState, ModelRuntimeState.idle);

    stuckClassifier.completeLoad();
    await stuckPreparation;
    expect(controller.modelState, ModelRuntimeState.idle);
    controller.dispose();
  });

  test('failed model with stuck disposal does not block replacement',
      () async {
    final failedClassifier = _FailedClassifierWithStuckDisposal();
    final replacementClassifier = _LoadableClassifier();
    var factoryCalls = 0;
    final controller = AppController(
      taxonomy: await TaxonomyRepository.loadFromAssets(),
      historyRepository: _MemoryHistoryRepository(),
      classifierFactory: (_, _) {
        factoryCalls += 1;
        return factoryCalls == 1
            ? failedClassifier
            : replacementClassifier;
      },
    );

    await controller.prepareModel();
    expect(controller.modelState, ModelRuntimeState.error);

    await controller
        .switchInferenceConfiguration(
          modelVariant: ModelVariant.w8a16,
          useGpu: false,
        )
        .timeout(const Duration(milliseconds: 200));
    await controller.prepareModel();

    expect(controller.modelVariant, ModelVariant.w8a16);
    expect(controller.useGpu, isFalse);
    expect(replacementClassifier.isLoaded, isTrue);
    expect(controller.modelState, ModelRuntimeState.ready);
    failedClassifier.completeDisposal();
    controller.dispose();
  });

  test('failed model can retry the same inference configuration',
      () async {
    final failedClassifier = _FailedClassifierWithStuckDisposal();
    final replacementClassifier = _LoadableClassifier();
    var factoryCalls = 0;
    final controller = AppController(
      taxonomy: await TaxonomyRepository.loadFromAssets(),
      historyRepository: _MemoryHistoryRepository(),
      classifierFactory: (_, _) {
        factoryCalls += 1;
        return factoryCalls == 1
            ? failedClassifier
            : replacementClassifier;
      },
    );

    await controller.prepareModel();
    expect(controller.modelState, ModelRuntimeState.error);

    await controller.switchInferenceConfiguration(
      modelVariant: ModelVariant.fp32,
      useGpu: true,
    );
    await controller.prepareModel();

    expect(factoryCalls, 2);
    expect(replacementClassifier.isLoaded, isTrue);
    expect(controller.modelState, ModelRuntimeState.ready);
    failedClassifier.completeDisposal();
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

class _FailedClassifierWithStuckDisposal implements InsectClassifier {
  final Completer<void> _disposeCompleter = Completer<void>();

  @override
  bool get isLoaded => false;

  @override
  Future<List<RecognitionPrediction>> classify(Uint8List imageBytes) {
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() => _disposeCompleter.future;

  @override
  Future<void> load() {
    throw StateError('model load failed');
  }

  void completeDisposal() {
    _disposeCompleter.complete();
  }
}

class _LoadableClassifier implements InsectClassifier {
  bool _isLoaded = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<List<RecognitionPrediction>> classify(Uint8List imageBytes) async {
    return const <RecognitionPrediction>[];
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load() async {
    _isLoaded = true;
  }
}
