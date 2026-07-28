import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../models/taxon_info.dart';
import 'model_labels_screen.dart';

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
            const _AppHeader(),
            const SizedBox(height: 28),
            const _SectionTitle('识别能力'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: <Widget>[
                  const ListTile(
                    leading: Icon(Icons.model_training_outlined),
                    title: Text('识别模型'),
                    subtitle: Text('Ultralytics YOLO 分类模型'),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.smartphone_outlined),
                    title: Text('推理方式'),
                    subtitle: Text('完全在设备本地通过 LiteRT / TFLite 运行'),
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
            const SizedBox(height: 24),
            const _SectionTitle('数据与隐私'),
            const SizedBox(height: 10),
            Card(
              child: const Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.cloud_off_outlined),
                    title: Text('照片不会上传'),
                    subtitle: Text('图片裁切与昆虫识别均在本机完成'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('历史记录保存在应用私有目录'),
                    subtitle: Text('可在历史记录中删除；卸载应用时也会一并清除'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.perm_media_outlined),
                    title: Text('按需访问相机与相册'),
                    subtitle: Text('仅在拍照或选择待识别图片时使用'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('识别结果说明'),
            const SizedBox(height: 10),
            Card(
              color: colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '模型标签包含物种级、属级、科级和总科级分类。应用会按模型输出显示对应识别层级，不将高阶分类结果表述为具体物种。识别结果和置信度仅供参考，不能替代专业鉴定。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('技术与许可'),
            const SizedBox(height: 10),
            const Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.code_outlined),
                    title: Text('主要技术'),
                    subtitle: Text('Flutter · Material 3 · Ultralytics YOLO · LiteRT'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.description_outlined),
                    title: Text('许可提示'),
                    subtitle: Text('公开分发或商业使用前，请核对所用组件与模型的许可要求'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '感谢使用虫鉴',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: <Widget>[
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Icon(
            Icons.bug_report_rounded,
            size: 48,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(AppInfo.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          '设备端昆虫图像识别',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '版本 ${AppInfo.versionLabel}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}
