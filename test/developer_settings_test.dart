import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:insect_identifier/controllers/developer_settings_controller.dart';
import 'package:insect_identifier/models/model_variant.dart';
import 'package:insect_identifier/repositories/developer_settings_repository.dart';

void main() {
  test('developer settings default to disabled FP32 with GPU', () async {
    final repository = _MemoryDeveloperSettingsRepository();
    final controller = DeveloperSettingsController(repository);

    await controller.initialize();

    expect(controller.developerModeEnabled, isFalse);
    expect(controller.modelVariant, ModelVariant.fp32);
    expect(controller.useGpu, isTrue);
  });

  test('developer mode, model and inference device are persisted', () async {
    final repository = _MemoryDeveloperSettingsRepository();
    final controller = DeveloperSettingsController(repository);
    await controller.initialize();

    await controller.enableDeveloperMode();
    await controller.updateModelVariant(ModelVariant.w8a16);
    await controller.updateUseGpu(false);

    final restored = DeveloperSettingsController(repository);
    await restored.initialize();
    expect(restored.developerModeEnabled, isTrue);
    expect(restored.modelVariant, ModelVariant.w8a16);
    expect(restored.useGpu, isFalse);

    await restored.disableDeveloperMode();

    final disabled = DeveloperSettingsController(repository);
    await disabled.initialize();
    expect(disabled.developerModeEnabled, isFalse);
    expect(disabled.modelVariant, ModelVariant.w8a16);
    expect(disabled.useGpu, isFalse);
  });

  test('W8A16 can be persisted with GPU enabled', () async {
    final repository = _MemoryDeveloperSettingsRepository();
    final controller = DeveloperSettingsController(repository);
    await controller.initialize();

    await controller.updateInferenceSettings(
      modelVariant: ModelVariant.w8a16,
      useGpu: true,
    );

    expect(controller.modelVariant, ModelVariant.w8a16);
    expect(controller.useGpu, isTrue);
    expect(repository.settings.modelVariant, ModelVariant.w8a16);
    expect(repository.settings.useGpu, isTrue);
  });

  test('legacy W8A32 selection migrates to W8A16', () {
    final settings = DeveloperSettingsData.fromJson(
      <String, dynamic>{
        'developerModeEnabled': true,
        'modelVariant': 'w8a32',
      },
    );

    expect(settings.modelVariant, ModelVariant.w8a16);
    expect(settings.useGpu, isTrue);
  });

  test('GPU preference survives JSON serialization', () {
    final encoded = DeveloperSettingsData.defaults
        .copyWith(useGpu: false)
        .toJson();
    final restored = DeveloperSettingsData.fromJson(
      Map<String, dynamic>.from(encoded),
    );

    expect(encoded['schemaVersion'], 3);
    expect(restored.useGpu, isFalse);
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
    expect(settings.useGpu, isTrue);
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
