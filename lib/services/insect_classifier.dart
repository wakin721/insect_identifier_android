import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../models/model_variant.dart';
import '../models/recognition_prediction.dart';
import 'classification_output_parser.dart';

typedef InsectClassifierFactory = InsectClassifier Function(
  ModelVariant variant,
  bool useGpu,
);

abstract interface class InsectClassifier {
  bool get isLoaded;

  Future<void> load();

  Future<List<RecognitionPrediction>> classify(Uint8List imageBytes);

  Future<void> dispose();
}

class YoloInsectClassifier implements InsectClassifier {
  YoloInsectClassifier({
    this.modelPath = 'assets/models/insect_classifier_fp32.tflite',
    this.useGpu = true,
    this.loadTimeout = const Duration(seconds: 20),
    this.inferenceTimeout = const Duration(seconds: 30),
  });

  final String modelPath;
  final bool useGpu;
  final Duration loadTimeout;
  final Duration inferenceTimeout;

  YOLO? _yolo;
  bool _isLoaded = false;
  bool _disposed = false;
  int _loadGeneration = 0;
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
    final output = await _backgroundInferenceChannel
        .invokeMapMethod<String, dynamic>(
          'predictSingleImage',
          <String, Object>{
            'instanceId': yolo.instanceId,
            'image': imageBytes,
            'confidenceThreshold': 0.0,
          },
        )
        .timeout(
          inferenceTimeout,
          onTimeout: () => throw TimeoutException(
            '识别超过 ${inferenceTimeout.inSeconds} 秒，'
            '请尝试关闭 GPU 推理或切换模型。',
          ),
        );
    if (output == null) {
      throw StateError('Android 后台推理没有返回结果。');
    }
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
    if (_disposed) {
      throw StateError('模型实例已经释放。');
    }

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
          useMultiInstance: true,
        );
    _yolo = yolo;

    final generation = ++_loadGeneration;
    final future = _loadModel(yolo, generation);
    _modelLoading = future;
    return future;
  }

  Future<YOLO> _loadModel(YOLO yolo, int generation) async {
    try {
      return await _initializeModel(yolo, generation).timeout(
        loadTimeout,
        onTimeout: () {
          if (generation == _loadGeneration) {
            _loadGeneration += 1;
          }
          throw TimeoutException(
            '模型初始化超过 ${loadTimeout.inSeconds} 秒，'
            '请尝试关闭 GPU 推理或切换模型。',
          );
        },
      );
    } finally {
      _modelLoading = null;
    }
  }

  Future<YOLO> _initializeModel(YOLO yolo, int generation) async {
    final loaded = await yolo.loadModel();
    if (!loaded) {
      throw StateError('无法加载 Android LiteRT 分类模型。');
    }
    await _backgroundInferenceChannel.invokeMethod<void>(
      'predictorInstance',
      <String, Object>{'instanceId': yolo.instanceId},
    );
    if (_disposed || generation != _loadGeneration) {
      throw StateError('模型初始化已取消。');
    }
    _isLoaded = true;
    return yolo;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _loadGeneration += 1;
    final yolo = _yolo;
    _yolo = null;
    _modelLoading = null;
    _isLoaded = false;
    if (yolo == null) {
      return;
    }
    try {
      await _backgroundInferenceChannel.invokeMethod<void>(
        'disposeInstance',
        <String, Object>{'instanceId': yolo.instanceId},
      );
    } finally {
      await yolo.dispose();
    }
  }

  static const MethodChannel _backgroundInferenceChannel = MethodChannel(
    'top.myneri.insectidentifier/background_yolo',
  );
}
