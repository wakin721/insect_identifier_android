import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract interface class SettingsRepository {
  Future<int?> loadThemeColorValue();

  Future<void> saveThemeColorValue(int value);
}

class FileSettingsRepository implements SettingsRepository {
  static const _folderName = 'insect_identifier';
  static const _fileName = 'settings.json';

  @override
  Future<int?> loadThemeColorValue() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return null;
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final value = decoded['themeColor'];
      return value is int ? value : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> saveThemeColorValue(int value) async {
    final file = await _settingsFile();
    final tempFile = File('${file.path}.tmp');
    final payload = const JsonEncoder.withIndent('  ').convert(
      <String, Object>{'themeColor': value},
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
