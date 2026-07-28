import 'dart:typed_data';

import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../models/recognition_prediction.dart';
import 'classification_output_parser.dart';

abstract interface class InsectClassifier {
  bool get isLoaded;

  Future<void> load();

  Future<List<RecognitionPrediction>> classify(Uint8List imageBytes);

  Future<void> dispose();
}

class YoloInsectClassifier implements InsectClassifier {
  YoloInsectClassifier({
    this.modelPath = 'assets/models/insect_classifier.tflite',
    this.useGpu = true,
  });

  final String modelPath;
  final bool useGpu;

  YOLO? _yolo;
  bool _isLoaded = false;
  Future<YOLO>? _modelLoading;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> load() async {
    await _ensureModelLoaded();
  }

  @override
  Future<List<RecognitionPrediction>> classify(Uint8List imageBytes) async {
    final yolo = await _ensureModelLoaded();
    final output = await yolo.predict(
      imageBytes,
      confidenceThreshold: 0.0,
    );
    final predictions = ClassificationOutputParser.topPredictions(
      output,
      limit: 3,
    );
    if (predictions.isEmpty) {
      throw StateError('模型没有返回可用的分类结果。');
    }
    return predictions;
  }

  Future<YOLO> _ensureModelLoaded() async {
    final existing = _yolo;
    if (existing != null && _isLoaded) {
      return existing;
    }

    final loading = _modelLoading;
    if (loading != null) {
      return loading;
    }

    final yolo = existing ??
        YOLO(
          modelPath: modelPath,
          task: YOLOTask.classify,
          useGpu: useGpu,
        );
    _yolo = yolo;

    final future = _loadModel(yolo);
    _modelLoading = future;
    return future;
  }

  Future<YOLO> _loadModel(YOLO yolo) async {
    try {
      final loaded = await yolo.loadModel();
      if (!loaded) {
        throw StateError('无法加载 Android LiteRT 分类模型。');
      }
      _isLoaded = true;
      return yolo;
    } finally {
      _modelLoading = null;
    }
  }

  @override
  Future<void> dispose() async {
    final loading = _modelLoading;
    if (loading != null) {
      try {
        await loading;
      } on Object {
        // A failed load has no resources that need to be retained.
      }
    }
    await _yolo?.dispose();
    _yolo = null;
    _isLoaded = false;
  }
}
