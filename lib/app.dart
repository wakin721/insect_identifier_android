import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/app_controller.dart';
import 'controllers/appearance_controller.dart';
import 'controllers/developer_settings_controller.dart';
import 'core/app_info.dart';
import 'core/app_theme.dart';
import 'screens/home_shell.dart';

class InsectIdentifierApp extends StatefulWidget {
  const InsectIdentifierApp({
    required this.controller,
    required this.appearanceController,
    required this.developerSettingsController,
    super.key,
  });

  final AppController controller;
  final AppearanceController appearanceController;
  final DeveloperSettingsController developerSettingsController;

  @override
  State<InsectIdentifierApp> createState() => _InsectIdentifierAppState();
}

class _InsectIdentifierAppState extends State<InsectIdentifierApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          widget.controller.prepareModel(
            delayBeforeLoad: const Duration(milliseconds: 100),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    widget.developerSettingsController.dispose();
    widget.appearanceController.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appearanceController,
      builder: (context, _) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final useDynamic = widget.appearanceController.useDynamicColor;
            final lightScheme = useDynamic && lightDynamic != null
                ? lightDynamic
                : ColorScheme.fromSeed(
                    seedColor: widget.appearanceController.seedColor,
                    brightness: Brightness.light,
                  );
            final darkScheme = useDynamic && darkDynamic != null
                ? darkDynamic
                : ColorScheme.fromSeed(
                    seedColor: widget.appearanceController.seedColor,
                    brightness: Brightness.dark,
                  );

            return MaterialApp(
              title: AppInfo.name,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.fromColorScheme(lightScheme),
              darkTheme: AppTheme.fromColorScheme(darkScheme),
              themeMode: widget.appearanceController.themeMode,
              locale: const Locale('zh', 'CN'),
              supportedLocales: const <Locale>[Locale('zh', 'CN')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: HomeShell(
                controller: widget.controller,
                appearanceController: widget.appearanceController,
                developerSettingsController:
                    widget.developerSettingsController,
              ),
            );
          },
        );
      },
    );
  }
}
