import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/app_controller.dart';
import 'controllers/appearance_controller.dart';
import 'core/app_theme.dart';
import 'screens/home_shell.dart';

class InsectIdentifierApp extends StatefulWidget {
  const InsectIdentifierApp({
    required this.controller,
    required this.appearanceController,
    super.key,
  });

  final AppController controller;
  final AppearanceController appearanceController;

  @override
  State<InsectIdentifierApp> createState() => _InsectIdentifierAppState();
}

class _InsectIdentifierAppState extends State<InsectIdentifierApp> {
  @override
  void dispose() {
    widget.appearanceController.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appearanceController,
      builder: (context, _) {
        return MaterialApp(
          title: '虫鉴',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(widget.appearanceController.seedColor),
          darkTheme: AppTheme.dark(widget.appearanceController.seedColor),
          themeMode: widget.appearanceController.themeMode,
          locale: const Locale('zh', 'CN'),
          supportedLocales: const <Locale>[Locale('zh', 'CN')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: HomeShell(
            controller: widget.controller,
            appearanceController: widget.appearanceController,
          ),
        );
      },
    );
  }
}
