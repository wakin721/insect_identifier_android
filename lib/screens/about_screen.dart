import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(
                        Icons.bug_report_rounded,
                        size: 56,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('虫鉴', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Insect Identifier',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '设备端 YOLO 昆虫图像分类应用',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Card(
                  child: Column(
                    children: const <Widget>[
                      _AboutItem(
                        icon: Icons.info_outline_rounded,
                        title: '版本',
                        value: '1.0.1 (2)',
                      ),
                      Divider(height: 1),
                      _AboutItem(
                        icon: Icons.model_training_outlined,
                        title: '识别模型',
                        value: 'Ultralytics YOLO 分类模型',
                      ),
                      Divider(height: 1),
                      _AboutItem(
                        icon: Icons.memory_rounded,
                        title: '推理方式',
                        value: '设备本地 LiteRT / TFLite',
                      ),
                      Divider(height: 1),
                      _AboutItem(
                        icon: Icons.category_outlined,
                        title: '模型类别',
                        value: '19 个分类标签',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.privacy_tip_outlined,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text('数据与隐私', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '照片识别在设备本地完成，不会由应用代码上传。识别历史和裁切图像保存在应用私有目录中。识别结果仅用于辅助判断。',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.science_outlined,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text('分类学说明', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '模型标签包含物种级、科级和总科级分类。应用会按模型输出显示对应识别层级，不将高阶分类结果表述为具体物种。',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  const _AboutItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
