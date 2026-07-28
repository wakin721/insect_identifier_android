import 'package:flutter/material.dart';

import 'app.dart';
import 'controllers/app_controller.dart';
import 'controllers/appearance_controller.dart';
import 'controllers/developer_settings_controller.dart';
import 'repositories/developer_settings_repository.dart';
import 'repositories/history_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/taxonomy_repository.dart';
import 'services/insect_classifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final taxonomy = await TaxonomyRepository.loadFromAssets();
  final developerSettingsController = DeveloperSettingsController(
    FileDeveloperSettingsRepository(),
  );
  await developerSettingsController.initialize();

  final controller = AppController(
    taxonomy: taxonomy,
    historyRepository: FileHistoryRepository(),
    initialModelVariant: developerSettingsController.modelVariant,
    classifierFactory: (variant) => YoloInsectClassifier(
      modelPath: variant.assetPath,
    ),
  );
  await controller.initialize();

  final appearanceController = AppearanceController(
    FileSettingsRepository(),
  );
  await appearanceController.initialize();

  runApp(
    InsectIdentifierApp(
      controller: controller,
      appearanceController: appearanceController,
      developerSettingsController: developerSettingsController,
    ),
  );
}
