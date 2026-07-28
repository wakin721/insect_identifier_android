import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../controllers/developer_settings_controller.dart';
import '../core/app_info.dart';
import '../models/taxon_info.dart';
import 'developer_options_screen.dart';
import 'model_labels_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({
    required this.modelClassCount,
    required this.classes,
    required this.appController,
    required this.developerSettingsController,
    super.key,
  });

  final int modelClassCount;
  final List<TaxonInfo> classes;
  final AppController appController;
  final DeveloperSettingsController developerSettingsController;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const _requiredVersionTaps = 7;
  static const _tapResetWindow = Duration(seconds: 2);

  int _versionTapCount = 0;
  DateTime? _lastVersionTap;

  Future<void> _handleVersionTap() async {
    if (widget.developerSettingsController.developerModeEnabled) {
      await _openDeveloperOptions();
      return;
    }

    final now = DateTime.now();
    final lastTap = _lastVersionTap;
    if (lastTap == null || now.difference(lastTap) > _tapResetWindow) {
      _versionTapCount = 0;
    }
    _lastVersionTap = now;
    _versionTapCount += 1;

    if (_versionTapCount >= _requiredVersionTaps) {
      try {
        await widget.developerSettingsController.enableDeveloperMode();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('开发者模式启用失败：$error')),
            );
        }
        return;
      }
      if (!mounted) {
        return;
      }
      _versionTapCount = 0;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('开发者模式已启用')),
        );
      await _openDeveloperOptions();
      return;
    }

    if (_versionTapCount >= 3 && mounted) {
      final remaining = _requiredVersionTaps - _versionTapCount;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('再点击 $remaining 次即可启用开发者模式')),
        );
    }
  }

  Future<void> _openDeveloperOptions() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DeveloperOptionsScreen(
          appController: widget.appController,
          developerSettingsController:
              widget.developerSettingsController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.developerSettingsController,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _AppHeader(
                developerModeEnabled:
                    widget.developerSettingsController.developerModeEnabled,
                onVersionTap: _handleVersionTap,
              ),
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
                      subtitle: Text('${widget.modelClassCount} 个分类标签'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ModelLabelsScreen(classes: widget.classes),
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
              Card(
                child: Column(
                  children: <Widget>[
                    const ListTile(
                      leading: Icon(Icons.code_outlined),
                      title: Text('主要技术'),
                      subtitle:
                          Text('Flutter · Material 3 · Ultralytics YOLO · LiteRT'),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      leading: Icon(Icons.balance_outlined),
                      title: Text('开源许可'),
                      subtitle: Text('GNU Affero General Public License v3.0'),
                    ),
                  ],
                ),
              ),
              if (widget.developerSettingsController.developerModeEnabled)
                ...<Widget>[
                  const SizedBox(height: 24),
                  const _SectionTitle('开发者模式'),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.developer_mode_outlined),
                      title: const Text('开发者选项'),
                      subtitle: Text(
                        '当前模型：${widget.appController.modelVariant.displayName}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openDeveloperOptions,
                    ),
                  ),
                ],
              const SizedBox(height: 24),
              Text(
                '感谢使用虫鉴',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Copyright © 2026 wakin721 and contributors\n'
                'GNU AGPL-3.0 · 本程序不提供任何担保',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({
    required this.developerModeEnabled,
    required this.onVersionTap,
  });

  final bool developerModeEnabled;
  final VoidCallback onVersionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: <Widget>[
        ClipOval(
          child: Image.asset(
            'assets/images/app_icon.png',
            semanticLabel: '虫鉴应用图标',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            width: 88,
            height: 88,
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
        Semantics(
          button: true,
          excludeSemantics: true,
          label: developerModeEnabled
              ? '版本 ${AppInfo.versionLabel}，打开开发者选项'
              : '版本 ${AppInfo.versionLabel}',
          child: Material(
            color: colorScheme.secondaryContainer,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onVersionTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      '版本 ${AppInfo.versionLabel}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
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
