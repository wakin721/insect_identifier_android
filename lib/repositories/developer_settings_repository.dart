import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/model_variant.dart';

class DeveloperSettingsData {
  const DeveloperSettingsData({
    required this.developerModeEnabled,
    required this.modelVariant,
    required this.useGpu,
  });

  static const defaults = DeveloperSettingsData(
    developerModeEnabled: false,
    modelVariant: ModelVariant.fp32,
    useGpu: true,
  );

  final bool developerModeEnabled;
  final ModelVariant modelVariant;
  final bool useGpu;

  DeveloperSettingsData copyWith({
    bool? developerModeEnabled,
    ModelVariant? modelVariant,
    bool? useGpu,
  }) {
    return DeveloperSettingsData(
      developerModeEnabled:
          developerModeEnabled ?? this.developerModeEnabled,
      modelVariant: modelVariant ?? this.modelVariant,
      useGpu: useGpu ?? this.useGpu,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
        'schemaVersion': 3,
        'developerModeEnabled': developerModeEnabled,
        'modelVariant': modelVariant.storageValue,
        'useGpu': useGpu,
      };

  factory DeveloperSettingsData.fromJson(Map<String, dynamic> json) {
    final enabled = json['developerModeEnabled'];
    final useGpu = json['useGpu'];
    return DeveloperSettingsData(
      developerModeEnabled: enabled is bool ? enabled : false,
      modelVariant: ModelVariant.fromStorageValue(json['modelVariant']),
      useGpu: useGpu is bool ? useGpu : true,
    );
  }
}

abstract interface class DeveloperSettingsRepository {
  Future<DeveloperSettingsData> load();

  Future<void> save(DeveloperSettingsData settings);
}

class FileDeveloperSettingsRepository
    implements DeveloperSettingsRepository {
  FileDeveloperSettingsRepository({
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  static const _folderName = 'insect_identifier';
  static const _fileName = 'developer_settings.json';

  final Future<Directory> Function() _documentsDirectoryProvider;

  @override
  Future<DeveloperSettingsData> load() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return DeveloperSettingsData.defaults;
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return DeveloperSettingsData.defaults;
      }
      return DeveloperSettingsData.fromJson(decoded);
    } on FormatException {
      return DeveloperSettingsData.defaults;
    } on TypeError {
      return DeveloperSettingsData.defaults;
    }
  }

  @override
  Future<void> save(DeveloperSettingsData settings) async {
    final file = await _settingsFile();
    final tempFile = File('${file.path}.tmp');
    final payload = const JsonEncoder.withIndent(' ').convert(
      settings.toJson(),
    );
    await tempFile.writeAsString(payload);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  Future<File> _settingsFile() async {
    final documents = await _documentsDirectoryProvider();
    final root = Directory(
      '${documents.path}${Platform.pathSeparator}$_folderName',
    );
    await root.create(recursive: true);
    return File('${root.path}${Platform.pathSeparator}$_fileName');
  }
}
