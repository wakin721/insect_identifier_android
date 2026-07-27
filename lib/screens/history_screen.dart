import 'dart:io';

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/recognition_record.dart';
import '../models/taxon_info.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text('历史识别 · ${controller.history.length}'),
            actions: <Widget>[
              IconButton(
                tooltip: '清空全部历史',
                onPressed: controller.history.isEmpty
                    ? null
                    : () => _confirmClear(context),
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
          body: controller.historyLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: controller.history.isEmpty
                          ? const _EmptyHistory()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                              itemCount: controller.history.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final record = controller.history[index];
                                return _HistoryItem(
                                  record: record,
                                  taxon: controller.taxonomy.find(
                                    record.predictions.first,
                                  ),
                                  onOpen: () => _openRecord(context, record),
                                  onDelete: () =>
                                      _confirmDelete(context, record),
                                );
                              },
                            ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _openRecord(
    BuildContext context,
    RecognitionRecord record,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ResultScreen(
          record: record,
          taxonomy: controller.taxonomy,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RecognitionRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录？'),
        content: const Text('对应的裁切照片也会从本机应用目录中删除。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteRecord(record);
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空全部历史？'),
        content: const Text('此操作会删除全部本地识别记录及其裁切照片，无法撤销。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('全部清空'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearHistory();
    }
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.record,
    required this.taxon,
    required this.onOpen,
    required this.onDelete,
  });

  final RecognitionRecord record;
  final TaxonInfo taxon;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final prediction = record.predictions.first;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.square(
                  dimension: 78,
                  child: Image.file(
                    File(record.imagePath),
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      taxon.commonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      taxon.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: taxon.italicizeScientificName
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${_formatDateTime(record.createdAt)}  ·  '
                      '${(prediction.confidence * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '删除',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.history_toggle_off_rounded,
              size: 68,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '还没有识别记录',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              '完成一次识别后，Top 3 结果和裁切照片会保存在本机。',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
