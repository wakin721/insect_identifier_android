import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  late final Future<String> _licenseText;

  @override
  void initState() {
    super.initState();
    _licenseText = rootBundle.loadString('LICENSE');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('开源许可')),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _licenseText,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('无法读取许可证正文。'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return SelectionArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '虫鉴',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Copyright © 2026 wakin721 and contributors',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '本程序采用 GNU Affero General Public License '
                            'Version 3 发布，不提供任何担保。你可以依照该许可运行、'
                            '研究、修改和传播本程序。',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '对应源代码：\n'
                            'https://github.com/wakin721/'
                            'insect_identifier_android',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('完整许可证', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(
                    snapshot.data!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
