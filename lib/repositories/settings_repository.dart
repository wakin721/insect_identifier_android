import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppearanceSettingsData {
  const AppearanceSettingsData({
    required this.themeMode,
    required this.useDynamicColor,
    required this.seedColorValue,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 2;
  static const int previousDefaultSeedColor = 0xff386a20;
  static const int defaultSeedColor = 0xff984061;

  static const defaults = AppearanceSettingsData(
    themeMode: 'system',
    useDynamicColor: false,
    seedColorValue: defaultSeedColor,
  );

  final String themeMode;
  final bool useDynamicColor;
  final int seedColorValue;
  final int schemaVersion;

  Map<String, Object> toJson() => <String, Object>{
        'schemaVersion': schemaVersion,
        'themeMode': themeMode,
        'useDynamicColor': useDynamicColor,
        'seedColor': seedColorValue,
      };

  factory AppearanceSettingsData.fromJson(Map<String, dynamic> json) {
    final themeMode = json['themeMode'];
    final useDynamicColor = json['useDynamicColor'];
    final seedColor = json['seedColor'] ?? json['themeColor'];
    final schemaVersion = json['schemaVersion'];

    final storedSeedColor =
        seedColor is int ? seedColor : defaults.seedColorValue;
    final migratedSeedColor = schemaVersion is int &&
            schemaVersion >= currentSchemaVersion
        ? storedSeedColor
        : storedSeedColor == previousDefaultSeedColor
            ? defaultSeedColor
            : storedSeedColor;

    return AppearanceSettingsData(
      themeMode: themeMode is String ? themeMode : defaults.themeMode,
      useDynamicColor: useDynamicColor is bool
          ? useDynamicColor
          : defaults.useDynamicColor,
      seedColorValue: migratedSeedColor,
    );
  }
}

abstract interface class SettingsRepository {
  Future<AppearanceSettingsData> load();

  Future<void> save(AppearanceSettingsData settings);
}

class FileSettingsRepository implements SettingsRepository {
  static const _folderName = 'insect_identifier';
  static const _fileName = 'settings.json';

  @override
  Future<AppearanceSettingsData> load() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return AppearanceSettingsData.defaults;
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return AppearanceSettingsData.defaults;
      }
      return AppearanceSettingsData.fromJson(decoded);
    } on FormatException {
      return AppearanceSettingsData.defaults;
    } on TypeError {
      return AppearanceSettingsData.defaults;
    }
  }

  @override
  Future<void> save(AppearanceSettingsData settings) async {
    final file = await _settingsFile();
    final tempFile = File('${file.path}.tmp');
    final payload = const JsonEncoder.withIndent('  ').convert(
      settings.toJson(),
    );
    await tempFile.writeAsString(payload, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory(
      '${documents.path}${Platform.pathSeparator}$_folderName',
    );
    await root.create(recursive: true);
    return File('${root.path}${Platform.pathSeparator}$_fileName');
  }
}
