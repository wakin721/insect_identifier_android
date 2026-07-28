import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insect_identifier/controllers/app_controller.dart';
import 'package:insect_identifier/controllers/developer_settings_controller.dart';
import 'package:insect_identifier/core/app_info.dart';
import 'package:insect_identifier/models/recognition_prediction.dart';
import 'package:insect_identifier/models/recognition_record.dart';
import 'package:insect_identifier/repositories/developer_settings_repository.dart';
import 'package:insect_identifier/repositories/history_repository.dart';
import 'package:insect_identifier/repositories/taxonomy_repository.dart';
import 'package:insect_identifier/screens/about_screen.dart';
import 'package:insect_identifier/services/insect_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('seven consecutive version taps enable developer mode',
      (tester) async {
    final developerController = DeveloperSettingsController(
      _MemoryDeveloperSettingsRepository(),
    );
    await developerController.initialize();
    final taxonomy = await TaxonomyRepository.loadFromAssets();
    final appController = AppController(
      taxonomy: taxonomy,
      historyRepository: _MemoryHistoryRepository(),
      classifierFactory: (_, _) => _ImmediateClassifier(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AboutScreen(
          modelClassCount: taxonomy.classes.length,
          classes: taxonomy.classes,
          appController: appController,
          developerSettingsController: developerController,
        ),
      ),
    );

    expect(
      find.textContaining('本程序不提供任何担保'),
      findsNothing,
    );

    final version = find.text('版本 ${AppInfo.versionLabel}');
    for (var tap = 0; tap < 7; tap += 1) {
      await tester.tap(version);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(developerController.developerModeEnabled, isTrue);
    expect(find.text('开发者选项'), findsOneWidget);
    expect(find.text('FP32'), findsOneWidget);
    expect(find.text('W8A16'), findsOneWidget);
    expect(find.text('使用 GPU 推理'), findsOneWidget);
    expect(find.text('当前'), findsNothing);
    expect(find.text('启用开发者选项'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('使用 GPU 推理'),
      200,
    );
    final gpuSwitch = find.descendant(
      of: find.widgetWithText(SwitchListTile, '使用 GPU 推理'),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(gpuSwitch);
    await tester.tap(gpuSwitch);
    await tester.pumpAndSettle();

    expect(developerController.useGpu, isFalse);
    expect(appController.useGpu, isFalse);

    await tester.scrollUntilVisible(
      find.text('启用开发者选项'),
      200,
    );
    final developerModeSwitch = find.descendant(
      of: find.widgetWithText(SwitchListTile, '启用开发者选项'),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(developerModeSwitch);
    await tester.tap(developerModeSwitch);
    await tester.pumpAndSettle();

    expect(developerController.developerModeEnabled, isFalse);
    expect(find.text('推理模型'), findsNothing);

    appController.dispose();
    developerController.dispose();
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

class _ImmediateClassifier implements InsectClassifier {
  @override
  bool get isLoaded => false;

  @override
  Future<List<RecognitionPrediction>> classify(Uint8List imageBytes) async {
    return const <RecognitionPrediction>[];
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> load() async {}
}

class _MemoryHistoryRepository implements HistoryRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<void> delete(RecognitionRecord record) async {}

  @override
  Future<List<RecognitionRecord>> loadAll() async {
    return const <RecognitionRecord>[];
  }

  @override
  Future<RecognitionRecord> save({
    required Uint8List imageBytes,
    required List<RecognitionPrediction> predictions,
  }) {
    throw UnimplementedError();
  }
}
