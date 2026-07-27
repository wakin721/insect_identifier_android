import 'package:flutter/material.dart';

import 'app.dart';
import 'controllers/app_controller.dart';
import 'repositories/history_repository.dart';
import 'repositories/taxonomy_repository.dart';
import 'services/insect_classifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final taxonomy = await TaxonomyRepository.loadFromAssets();
  final controller = AppController(
    taxonomy: taxonomy,
    historyRepository: FileHistoryRepository(),
    classifier: YoloInsectClassifier(),
  );
  await controller.initialize();

  runApp(InsectIdentifierApp(controller: controller));
}
