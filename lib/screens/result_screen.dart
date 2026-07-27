import 'dart:io';

import 'package:flutter/material.dart';

import '../models/recognition_prediction.dart';
import '../models/recognition_record.dart';
import '../models/taxon_info.dart';
import '../repositories/taxonomy_repository.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    required this.record,
    required this.taxonomy,
    super.key,
  });

  final RecognitionRecord record;
  final TaxonomyRepository taxonomy;

  @override
  Widget build(BuildContext context) {
    if (record.predictions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('该历史记录没有分类结果。')),
      );
    }

    final firstPrediction = record.predictions.first;
    final firstTaxon = taxonomy.find(firstPrediction);

    return Scaffold(
      appBar: AppBar(title: const Text('识别结果')),
      body: SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: <Widget>[
              Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _ResultImage(imagePath: record.imagePath),
                      const SizedBox(height: 16),
                      _PrimaryResultCard(
                        prediction: firstPrediction,
                        taxon: firstTaxon,
                      ),
                      const SizedBox(height: 16),
                      _TaxonomyCard(taxon: firstTaxon),
                      const SizedBox(height: 20),
                      Text(
                        '置信度 Top ${record.predictions.length}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      ...record.predictions.indexed.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PredictionCard(
                            rank: entry.$1 + 1,
                            prediction: entry.$2,
                            taxon: taxonomy.find(entry.$2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _DisclaimerCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultImage extends StatelessWidget {
  const _ResultImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          cacheWidth: 1400,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: const Center(
              child: Icon(Icons.broken_image_outlined, size: 54),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryResultCard extends StatelessWidget {
  const _PrimaryResultCard({
    required this.prediction,
    required this.taxon,
  });

  final RecognitionPrediction prediction;
  final TaxonInfo taxon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Chip(
                  avatar: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text('最可能结果'),
                ),
                const Spacer(),
                Text(
                  _formatConfidence(prediction.confidence),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              taxon.commonName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              taxon.scientificName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontStyle: taxon.italicizeScientificName
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: prediction.confidence.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxonomyCard extends StatelessWidget {
  const _TaxonomyCard({required this.taxon});

  final TaxonInfo taxon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.account_tree_outlined),
                const SizedBox(width: 10),
                Text(
                  '分类信息',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _TaxonomyRow(label: '识别层级', value: taxon.rankCn),
            _TaxonomyRow(label: '目', value: taxon.orderDisplay),
            _TaxonomyRow(label: '科', value: taxon.familyDisplay),
            _TaxonomyRow(label: '属', value: taxon.genusDisplay),
            if (taxon.note != null) ...<Widget>[
              const Divider(height: 24),
              Text(
                taxon.note!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaxonomyRow extends StatelessWidget {
  const _TaxonomyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({
    required this.rank,
    required this.prediction,
    required this.taxon,
  });

  final int rank;
  final RecognitionPrediction prediction;
  final TaxonInfo taxon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              child: Text('$rank'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          taxon.commonName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        _formatConfidence(prediction.confidence),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    taxon.scientificName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: taxon.italicizeScientificName
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${taxon.rankCn} · ${taxon.familyCn} · ${taxon.genusCn}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 9),
                  LinearProgressIndicator(
                    value: prediction.confidence.clamp(0.0, 1.0).toDouble(),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.info_outline_rounded, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '结果仅供辅助识别。置信度表示模型在现有训练类别中的相对判断，不等同于物种鉴定结论。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatConfidence(double confidence) {
  final normalized = confidence.clamp(0.0, 1.0).toDouble();
  return '${(normalized * 100).toStringAsFixed(1)}%';
}
