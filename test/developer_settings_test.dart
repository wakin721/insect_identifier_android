import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:insect_identifier/controllers/developer_settings_controller.dart';
import 'package:insect_identifier/models/model_variant.dart';
import 'package:insect_identifier/repositories/developer_settings_repository.dart';

void main() {
  test('developer settings default to disabled FP32', () async {
    final repository = _MemoryDeveloperSettingsRepository();
    final controller = DeveloperSettingsController(repository);

    await controller.initialize();

    expect(controller.developerModeEnabled, isFalse);
    expect(controller.modelVariant, ModelVariant.fp32);
  });

  test('developer mode and model selection are persisted', () async {
    final repository = _MemoryDeveloperSettingsRepository();
    final controller = DeveloperSettingsController(repository);
    await controller.initialize();

    await controller.enableDeveloperMode();
    await controller.updateModelVariant(ModelVariant.w8a32);

    final restored = DeveloperSettingsController(repository);
    await restored.initialize();
    expect(restored.developerModeEnabled, isTrue);
    expect(restored.modelVariant, ModelVariant.w8a32);
  });

  test('invalid stored model falls back to FP32', () async {
    final directory = await Directory.systemTemp.createTemp(
      'insect-developer-settings-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = FileDeveloperSettingsRepository(
      documentsDirectoryProvider: () async => directory,
    );
    final settingsDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}insect_identifier',
    );
    await settingsDirectory.create(recursive: true);
    await File(
      '${settingsDirectory.path}${Platform.pathSeparator}'
      'developer_settings.json',
    ).writeAsString(
      '{"developerModeEnabled":true,"modelVariant":"unknown"}',
    );

    final settings = await repository.load();

    expect(settings.developerModeEnabled, isTrue);
    expect(settings.modelVariant, ModelVariant.fp32);
  });
}

class _MemoryDeveloperSettingsRepository
    implements DeveloperSettingsRepository {
  DeveloperSettingsData settings = DeveloperSettingsData.defaults;

  @override
  Future<DeveloperSettingsData> load() async => settings;

  @override
  Future<void> save(DeveloperSettingsData settings) async {
    this.settings = settings;
  }
}
