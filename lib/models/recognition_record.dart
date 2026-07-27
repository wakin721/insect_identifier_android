import 'recognition_prediction.dart';

class RecognitionRecord {
  const RecognitionRecord({
    required this.id,
    required this.createdAt,
    required this.imagePath,
    required this.predictions,
  });

  final String id;
  final DateTime createdAt;
  final String imagePath;
  final List<RecognitionPrediction> predictions;

  factory RecognitionRecord.fromJson(Map<String, dynamic> json) {
    final rawPredictions = json['predictions'] as List<dynamic>? ?? const [];
    return RecognitionRecord(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      imagePath: json['image_path'] as String,
      predictions: rawPredictions
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) => RecognitionPrediction.fromJson(
              item.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'created_at': createdAt.toUtc().toIso8601String(),
      'image_path': imagePath,
      'predictions': predictions.map((item) => item.toJson()).toList(),
    };
  }
}
