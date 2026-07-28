enum ModelVariant {
  fp32(
    storageValue: 'fp32',
    displayName: 'FP32',
    assetPath: 'assets/models/insect_classifier_fp32.tflite',
    description: '兼容性优先的默认模型，权重和激活均使用 FP32。',
  ),
  w8a16(
    storageValue: 'w8a16',
    displayName: 'W8A16',
    assetPath: 'assets/models/insect_classifier_w8a16.tflite',
    description: 'INT8 权重与校准后的 INT16 激活，模型更小，性能取决于设备。',
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
    if (value == 'w8a32') {
      return ModelVariant.w8a16;
    }
    return ModelVariant.values.firstWhere(
      (variant) => variant.storageValue == value,
      orElse: () => ModelVariant.fp32,
    );
  }
}
