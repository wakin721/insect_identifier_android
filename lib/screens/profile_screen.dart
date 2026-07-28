import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../controllers/appearance_controller.dart';
import '../controllers/developer_settings_controller.dart';
import 'about_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.controller,
    required this.appearanceController,
    required this.developerSettingsController,
    super.key,
  });

  final AppController controller;
  final AppearanceController appearanceController;
  final DeveloperSettingsController developerSettingsController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('我的', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('历史识别'),
                subtitle: Text('${controller.history.length} 条记录'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HistoryScreen(controller: controller),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('外观与主题'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(
                      controller: appearanceController,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AboutScreen(
                      modelClassCount: controller.taxonomy.classes.length,
                      classes: controller.taxonomy.classes,
                      appController: controller,
                      developerSettingsController:
                          developerSettingsController,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
