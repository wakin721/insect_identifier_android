import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.bug_report_rounded, size: 72),
            SizedBox(height: 16),
            Text('虫鉴'),
            Text('YOLO 昆虫识别应用'),
            Text('Version 1.0.0'),
          ],
        ),
      ),
    );
  }
}
