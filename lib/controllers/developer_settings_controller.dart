import 'package:flutter/foundation.dart';

import '../models/model_variant.dart';
import '../repositories/developer_settings_repository.dart';

class DeveloperSettingsController extends ChangeNotifier {
  DeveloperSettingsController(this._repository);

  final DeveloperSettingsRepository _repository;
  DeveloperSettingsData _settings = DeveloperSettingsData.defaults;

  bool get developerModeEnabled => _settings.developerModeEnabled;
  ModelVariant get modelVariant => _settings.modelVariant;

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
    if (variant == modelVariant) {
      return;
    }
    final next = _settings.copyWith(modelVariant: variant);
    await _repository.save(next);
    _settings = next;
    notifyListeners();
  }
}
