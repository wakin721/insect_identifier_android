import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const colors = <Color>[
    Color(0xff386a20),
    Color(0xff00639b),
    Color(0xff6750a4),
    Color(0xff9a4520),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text('主题颜色', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            children: colors.map((color) {
              return InkWell(
                onTap: () {},
                child: CircleAvatar(backgroundColor: color),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
