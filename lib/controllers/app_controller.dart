import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/model_variant.dart';
import '../models/recognition_record.dart';
import '../repositories/history_repository.dart';
import '../repositories/taxonomy_repository.dart';
import '../services/insect_classifier.dart';

enum ModelRuntimeState { idle, loading, ready, error }

class AppController extends ChangeNotifier {
  AppController({
    required this.taxonomy,
    required HistoryRepository historyRepository,
    required InsectClassifierFactory classifierFactory,
    ModelVariant initialModelVariant = ModelVariant.fp32,
    bool initialUseGpu = true,
  })  : _historyRepository = historyRepository,
        _classifierFactory = classifierFactory,
        _modelVariant = initialModelVariant,
        _useGpu = initialUseGpu,
        _classifier = classifierFactory(initialModelVariant, initialUseGpu);

  final TaxonomyRepository taxonomy;
  final HistoryRepository _historyRepository;
  final InsectClassifierFactory _classifierFactory;
  InsectClassifier _classifier;

  List<RecognitionRecord> _history = const <RecognitionRecord>[];
  bool _historyLoading = true;
  bool _recognizing = false;
  ModelRuntimeState _modelState = ModelRuntimeState.idle;
  Future<void>? _modelPreparation;
  ModelVariant _modelVariant;
  bool _useGpu;
  String? _lastError;

  List<RecognitionRecord> get history => _history;
  bool get historyLoading => _historyLoading;
  bool get recognizing => _recognizing;
  ModelRuntimeState get modelState => _modelState;
  ModelVariant get modelVariant => _modelVariant;
  bool get useGpu => _useGpu;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    _historyLoading = true;
    notifyListeners();
    try {
      _history = List<RecognitionRecord>.unmodifiable(
        await _historyRepository.loadAll(),
      );
    } catch (error) {
      _history = const <RecognitionRecord>[];
      _lastError = '历史记录读取失败：$error';
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  Future<RecognitionRecord> recognize(Uint8List croppedImage) async {
    if (_recognizing) {
      throw StateError('已有识别任务正在运行。');
    }

    _recognizing = true;
    _modelState = ModelRuntimeState.loading;
    _lastError = null;
    notifyListeners();

    try {
      final predictions = await _classifier.classify(croppedImage);
      _modelState = ModelRuntimeState.ready;
      final record = await _historyRepository.save(
        imageBytes: croppedImage,
        predictions: predictions,
      );
      _history = List<RecognitionRecord>.unmodifiable(
        <RecognitionRecord>[
          record,
          ..._history.where((item) => item.id != record.id),
        ],
      );
      return record;
    } catch (error) {
      _modelState = ModelRuntimeState.error;
      _lastError = error.toString();
      rethrow;
    } finally {
      _recognizing = false;
      notifyListeners();
    }
  }

  Future<void> prepareModel({
    Duration delayBeforeLoad = Duration.zero,
  }) {
    if (_classifier.isLoaded) {
      if (_modelState != ModelRuntimeState.ready) {
        _modelState = ModelRuntimeState.ready;
        notifyListeners();
      }
      return Future<void>.value();
    }

    final activePreparation = _modelPreparation;
    if (activePreparation != null) {
      return activePreparation;
    }

    final preparation = _prepareModel(delayBeforeLoad);
    _modelPreparation = preparation;
    return preparation;
  }

  Future<void> _prepareModel(Duration delayBeforeLoad) async {
    _modelState = ModelRuntimeState.loading;
    _lastError = null;
    notifyListeners();
    try {
      if (delayBeforeLoad > Duration.zero) {
        await Future<void>.delayed(delayBeforeLoad);
      }
      await _classifier.load();
      if (!_recognizing) {
        _modelState = ModelRuntimeState.ready;
      }
    } catch (error) {
      _modelState = ModelRuntimeState.error;
      _lastError = '模型预加载失败：$error';
    } finally {
      _modelPreparation = null;
      notifyListeners();
    }
  }

  Future<void> switchModelVariant(ModelVariant variant) async {
    await _switchInferenceConfiguration(
      modelVariant: variant,
      useGpu: _useGpu,
    );
  }

  Future<void> switchUseGpu(bool useGpu) async {
    await _switchInferenceConfiguration(
      modelVariant: _modelVariant,
      useGpu: useGpu,
    );
  }

  Future<void> _switchInferenceConfiguration({
    required ModelVariant modelVariant,
    required bool useGpu,
  }) async {
    if (modelVariant == _modelVariant && useGpu == _useGpu) {
      return;
    }
    if (_recognizing) {
      throw StateError('识别进行中，暂时无法切换推理配置。');
    }

    final activePreparation = _modelPreparation;
    if (activePreparation != null) {
      await activePreparation;
    }
    if (_recognizing) {
      throw StateError('识别进行中，暂时无法切换推理配置。');
    }

    final previousClassifier = _classifier;
    _classifier = _classifierFactory(modelVariant, useGpu);
    _modelVariant = modelVariant;
    _useGpu = useGpu;
    _modelPreparation = null;
    _modelState = ModelRuntimeState.idle;
    _lastError = null;
    notifyListeners();
    await previousClassifier.dispose();
  }

  Future<void> deleteRecord(RecognitionRecord record) async {
    await _historyRepository.delete(record);
    _history = List<RecognitionRecord>.unmodifiable(
      _history.where((item) => item.id != record.id),
    );
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _historyRepository.clear();
    _history = const <RecognitionRecord>[];
    notifyListeners();
  }

  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_classifier.dispose());
    super.dispose();
  }
}
