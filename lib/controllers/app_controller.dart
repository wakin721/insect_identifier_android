import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/recognition_record.dart';
import '../repositories/history_repository.dart';
import '../repositories/taxonomy_repository.dart';
import '../services/insect_classifier.dart';

enum ModelRuntimeState { idle, loading, ready, error }

class AppController extends ChangeNotifier {
  AppController({
    required this.taxonomy,
    required HistoryRepository historyRepository,
    required InsectClassifier classifier,
  })  : _historyRepository = historyRepository,
        _classifier = classifier;

  final TaxonomyRepository taxonomy;
  final HistoryRepository _historyRepository;
  final InsectClassifier _classifier;

  List<RecognitionRecord> _history = const <RecognitionRecord>[];
  bool _historyLoading = true;
  bool _recognizing = false;
  ModelRuntimeState _modelState = ModelRuntimeState.idle;
  String? _lastError;

  List<RecognitionRecord> get history => _history;
  bool get historyLoading => _historyLoading;
  bool get recognizing => _recognizing;
  ModelRuntimeState get modelState => _modelState;
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
