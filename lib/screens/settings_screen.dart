import 'package:flutter/material.dart';

import '../controllers/appearance_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.controller, super.key});

  final AppearanceController controller;

  static const colors = <Color>[
    Color(0xff386a20),
    Color(0xff006b5f),
    Color(0xff00639b),
    Color(0xff6750a4),
    Color(0xff984061),
    Color(0xff9a4520),
    Color(0xff006874),
    Color(0xff7a5900),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('外观与主题')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text('主题模式', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const <ButtonSegment<ThemeMode>>[
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('浅色')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('深色')),
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('自动')),
                ],
                selected: <ThemeMode>{controller.themeMode},
                onSelectionChanged: (value) => controller.updateThemeMode(value.first),
              ),
              const Divider(height: 36),
              SwitchListTile(
                title: const Text('使用系统动态颜色'),
                subtitle: const Text('开启后调色板由系统主题接管'),
                value: controller.useDynamicColor,
                onChanged: controller.updateDynamicColor,
              ),
              const Divider(height: 36),
              Text('调色板', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: colors.map((color) {
                  final selected = controller.seedColor.value == color.value;
                  return InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () => controller.updateColor(color),
                    child: CircleAvatar(
                      radius: selected ? 34 : 32,
                      backgroundColor: color.withValues(alpha: .25),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: color,
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
