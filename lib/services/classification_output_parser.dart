import '../models/recognition_prediction.dart';

class ClassificationOutputParser {
  const ClassificationOutputParser._();

  static List<RecognitionPrediction> topPredictions(
    Map<String, dynamic> output, {
    int limit = 3,
  }) {
    if (limit <= 0) {
      return const <RecognitionPrediction>[];
    }

    final candidates = <RecognitionPrediction>[];
    final rawClassification = output['classification'];

    if (rawClassification is Map<dynamic, dynamic>) {
      final rawTopFive = rawClassification['top5'];
      if (rawTopFive is List<dynamic>) {
        for (final item in rawTopFive) {
          final prediction = _predictionFromRaw(item);
          if (prediction != null) {
            candidates.add(prediction);
          }
        }
      }

      if (candidates.isEmpty) {
        final prediction = _predictionFromRaw(rawClassification);
        if (prediction != null) {
          candidates.add(prediction);
        }
      }
    }

    if (candidates.isEmpty) {
      final rawDetections = output['detections'];
      if (rawDetections is List<dynamic>) {
        for (final item in rawDetections) {
          final prediction = _predictionFromRaw(item);
          if (prediction != null) {
            candidates.add(prediction);
          }
        }
      }
    }

    final unique = <String, RecognitionPrediction>{};
    for (final candidate in candidates) {
      final key = candidate.classIndex >= 0
          ? 'index:${candidate.classIndex}'
          : 'label:${candidate.modelLabel}';
      final existing = unique[key];
      if (existing == null || candidate.confidence > existing.confidence) {
        unique[key] = candidate;
      }
    }

    final sorted = unique.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return sorted.take(limit).toList(growable: false);
  }

  static RecognitionPrediction? _predictionFromRaw(Object? raw) {
    if (raw is! Map<dynamic, dynamic>) {
      return null;
    }

    final classIndex = _asInt(raw['class'] ?? raw['classIndex']);
    final label = (raw['name'] ?? raw['className'] ?? raw['class'])?.toString();
    final confidence = _asDouble(raw['confidence']);

    if (label == null || label.isEmpty || confidence == null) {
      return null;
    }

    return RecognitionPrediction(
      classIndex: classIndex ?? -1,
      modelLabel: label,
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      final result = value.toDouble();
      return result.isFinite ? result : null;
    }
    final result = double.tryParse(value?.toString() ?? '');
    return result != null && result.isFinite ? result : null;
  }
}
