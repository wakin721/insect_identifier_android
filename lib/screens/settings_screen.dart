import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Text('主题模式'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment(value: 'light', icon: Icon(Icons.light_mode), label: Text('浅色')),
              ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode), label: Text('深色')),
              ButtonSegment(value: 'system', icon: Icon(Icons.brightness_auto), label: Text('自动')),
            ],
            selected: const <String>{'system'},
            onSelectionChanged: (_) {},
          ),
          const Divider(height: 36),
          SwitchListTile(
            title: const Text('使用系统动态颜色'),
            subtitle: const Text('开启后调色板由系统主题接管'),
            value: false,
            onChanged: (_) {},
          ),
          const Divider(height: 36),
          Text('调色板', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: colors.map((color) {
              return InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () {},
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: color.withValues(alpha: 0.25),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: color,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
