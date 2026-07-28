import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';

class ModelStatusBanner extends StatelessWidget {
  const ModelStatusBanner({
    required this.state,
    required this.recognizing,
    super.key,
  });

  final ModelRuntimeState state;
  final bool recognizing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preparing = state == ModelRuntimeState.loading && !recognizing;
    final (icon, title, subtitle, color) = preparing
        ? (
            Icons.memory_outlined,
            '本地模型待命',
            '正在加载并预热本地模型，不上传照片',
            colorScheme.primary,
          )
        : switch (state) {
            ModelRuntimeState.idle => (
                Icons.memory_outlined,
                '本地模型待命',
                '即将加载本地模型，不上传照片',
                colorScheme.primary,
              ),
            ModelRuntimeState.loading => (
                Icons.hourglass_top_rounded,
                '正在分析照片',
                '正在解码照片并计算 Top 3',
                colorScheme.tertiary,
              ),
            ModelRuntimeState.ready => (
                Icons.offline_bolt_rounded,
                '本地模型已就绪',
                'LiteRT 推理引擎已预热，可离线运行',
                colorScheme.primary,
              ),
            ModelRuntimeState.error => (
                Icons.error_outline_rounded,
                '模型运行异常',
                '请切换模型、关闭 GPU 或重新识别',
                colorScheme.error,
              ),
          };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            SizedBox.square(
              dimension: 36,
              child: recognizing
                  ? const CircularProgressIndicator(strokeWidth: 3)
                  : Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (preparing) ...<Widget>[
              const SizedBox(width: 12),
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  semanticsLabel: '正在加载本地模型',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
