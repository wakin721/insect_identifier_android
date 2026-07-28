enum ModelVariant {
  fp32(
    storageValue: 'fp32',
    displayName: 'FP32',
    assetPath: 'assets/models/insect_classifier_fp32.tflite',
    description: '兼容性优先的默认模型，权重和激活均使用 FP32。',
  ),
  w8a32(
    storageValue: 'w8a32',
    displayName: 'W8A32',
    assetPath: 'assets/models/insect_classifier_w8a32.tflite',
    description: 'INT8 权重与 FP32 激活，模型更小，性能取决于设备。',
  );

  const ModelVariant({
    required this.storageValue,
    required this.displayName,
    required this.assetPath,
    required this.description,
  });

  final String storageValue;
  final String displayName;
  final String assetPath;
  final String description;

  static ModelVariant fromStorageValue(Object? value) {
    return ModelVariant.values.firstWhere(
      (variant) => variant.storageValue == value,
      orElse: () => ModelVariant.fp32,
    );
  }
}
