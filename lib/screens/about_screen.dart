import 'package:flutter/material.dart';

import 'model_labels_screen.dart';
import '../models/taxon_info.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({
    required this.modelClassCount,
    required this.classes,
    super.key,
  });

  final int modelClassCount;
  final List<TaxonInfo> classes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Card(
              child: Column(
                children: <Widget>[
                  const ListTile(
                    title: Text('识别模型'),
                    subtitle: Text('Ultralytics YOLO 分类模型'),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    title: Text('推理方式'),
                    subtitle: Text('设备本地 LiteRT / TFLite'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: const Text('模型类别'),
                    subtitle: Text('$modelClassCount 个分类标签'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ModelLabelsScreen(classes: classes),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  '模型标签包含物种级、属级、科级和总科级分类。应用会按模型输出显示对应识别层级，不将高阶分类结果表述为具体物种。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
