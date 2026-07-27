class RecognitionPrediction {
  const RecognitionPrediction({
    required this.classIndex,
    required this.modelLabel,
    required this.confidence,
  });

  final int classIndex;
  final String modelLabel;
  final double confidence;

  factory RecognitionPrediction.fromJson(Map<String, dynamic> json) {
    return RecognitionPrediction(
      classIndex: (json['class_index'] as num).toInt(),
      modelLabel: json['model_label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'class_index': classIndex,
      'model_label': modelLabel,
      'confidence': confidence,
    };
  }
}
