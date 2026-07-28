import 'package:flutter/material.dart';

import '../repositories/settings_repository.dart';
import '../services/launcher_icon_service.dart';

class AppearanceController extends ChangeNotifier {
  AppearanceController(this._repository);

  final SettingsRepository _repository;
  AppearanceSettingsData _settings = AppearanceSettingsData.defaults;

  AppearanceSettingsData get settings => _settings;
  bool get useDynamicColor => _settings.useDynamicColor;
  Color get seedColor => Color(_settings.seedColorValue);

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

  Future<void> initialize() async {
    _settings = await _repository.load();
    await LauncherIconService.schedule(
      useDynamicColor: useDynamicColor,
      seedColor: seedColor,
    );
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _settings = AppearanceSettingsData(
      themeMode: switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
      useDynamicColor: _settings.useDynamicColor,
      seedColorValue: _settings.seedColorValue,
    );
    notifyListeners();
    await _repository.save(_settings);
  }

  Future<void> updateColor(Color color) async {
    _settings = AppearanceSettingsData(
      themeMode: _settings.themeMode,
      useDynamicColor: _settings.useDynamicColor,
      seedColorValue: color.toARGB32(),
    );
    await LauncherIconService.schedule(
      useDynamicColor: useDynamicColor,
      seedColor: color,
    );
    notifyListeners();
    await _repository.save(_settings);
  }

  Future<void> updateDynamicColor(bool value) async {
    _settings = AppearanceSettingsData(
      themeMode: _settings.themeMode,
      useDynamicColor: value,
      seedColorValue: _settings.seedColorValue,
    );
    await LauncherIconService.schedule(
      useDynamicColor: value,
      seedColor: seedColor,
    );
    notifyListeners();
    await _repository.save(_settings);
  }
}
