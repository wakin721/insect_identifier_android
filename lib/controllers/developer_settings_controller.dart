import 'package:flutter/foundation.dart';

import '../models/model_variant.dart';
import '../repositories/developer_settings_repository.dart';

class DeveloperSettingsController extends ChangeNotifier {
  DeveloperSettingsController(this._repository);

  final DeveloperSettingsRepository _repository;
  DeveloperSettingsData _settings = DeveloperSettingsData.defaults;

  bool get developerModeEnabled => _settings.developerModeEnabled;
  ModelVariant get modelVariant => _settings.modelVariant;
  bool get useGpu => _settings.useGpu;

  Future<void> initialize() async {
    _settings = await _repository.load();
    notifyListeners();
  }

  Future<void> enableDeveloperMode() async {
    if (developerModeEnabled) {
      return;
    }
    final next = _settings.copyWith(developerModeEnabled: true);
    await _repository.save(next);
    _settings = next;
    notifyListeners();
  }

  Future<void> disableDeveloperMode() async {
    if (!developerModeEnabled) {
      return;
    }
    final next = _settings.copyWith(developerModeEnabled: false);
    await _repository.save(next);
    _settings = next;
    notifyListeners();
  }

  Future<void> updateModelVariant(ModelVariant variant) async {
    await updateInferenceSettings(
      modelVariant: variant,
      useGpu: useGpu,
    );
  }

  Future<void> updateUseGpu(bool useGpu) async {
    await updateInferenceSettings(
      modelVariant: modelVariant,
      useGpu: useGpu,
    );
  }

  Future<void> updateInferenceSettings({
    required ModelVariant modelVariant,
    required bool useGpu,
  }) async {
    if (modelVariant == this.modelVariant && useGpu == this.useGpu) {
      return;
    }
    final next = _settings.copyWith(
      modelVariant: modelVariant,
      useGpu: useGpu,
    );
    await _repository.save(next);
    _settings = next;
    notifyListeners();
  }
}
