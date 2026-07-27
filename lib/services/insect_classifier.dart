import 'dart:typed_data';

import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../models/recognition_prediction.dart';
import 'classification_output_parser.dart';

abstract interface class InsectClassifier {
  bool get isLoaded;

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

  @override
  bool get isLoaded => _isLoaded;

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

    final yolo = existing ??
        YOLO(
          modelPath: modelPath,
          task: YOLOTask.classify,
          useGpu: useGpu,
        );
    _yolo = yolo;

    final loaded = await yolo.loadModel();
    if (!loaded) {
      throw StateError('无法加载 Android LiteRT 分类模型。');
    }
    _isLoaded = true;
    return yolo;
  }

  @override
  Future<void> dispose() async {
    await _yolo?.dispose();
    _yolo = null;
    _isLoaded = false;
  }
}
