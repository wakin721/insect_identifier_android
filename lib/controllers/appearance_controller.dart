import 'package:flutter/material.dart';

import '../repositories/settings_repository.dart';

class AppearanceController extends ChangeNotifier {
  AppearanceController(this._repository);

  final SettingsRepository _repository;
  AppearanceSettingsData _settings = AppearanceSettingsData.defaults;

  AppearanceSettingsData get settings => _settings;

  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Color get seedColor => Color(_settings.seedColorValue);

  Future<void> initialize() async {
    _settings = await _repository.load();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _settings = AppearanceSettingsData(
      themeMode: switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      },
      useDynamicColor: _settings.useDynamicColor,
      seedColorValue: _settings.seedColorValue,
    );
    await _repository.save(_settings);
    notifyListeners();
  }

  Future<void> updateColor(Color color) async {
    _settings = AppearanceSettingsData(
      themeMode: _settings.themeMode,
      useDynamicColor: _settings.useDynamicColor,
      seedColorValue: color.value,
    );
    await _repository.save(_settings);
    notifyListeners();
  }

  Future<void> updateDynamicColor(bool value) async {
    _settings = AppearanceSettingsData(
      themeMode: _settings.themeMode,
      useDynamicColor: value,
      seedColorValue: _settings.seedColorValue,
    );
    await _repository.save(_settings);
    notifyListeners();
  }
}
