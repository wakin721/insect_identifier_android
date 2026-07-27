import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import 'history_screen.dart';
import 'recognize_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bug_report_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text('虫鉴'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          RecognizeScreen(controller: widget.controller),
          HistoryScreen(controller: widget.controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt_rounded),
            label: '识别',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: '历史',
          ),
        ],
      ),
    );
  }
}
