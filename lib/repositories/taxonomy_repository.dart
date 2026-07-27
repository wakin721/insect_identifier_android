import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/recognition_prediction.dart';
import '../models/taxon_info.dart';

class TaxonomyRepository {
  TaxonomyRepository._(this.classes)
      : _byLabel = <String, TaxonInfo>{
          for (final item in classes) item.modelLabel: item,
        },
        _byIndex = <int, TaxonInfo>{
          for (final item in classes) item.classIndex: item,
        };

  final List<TaxonInfo> classes;
  final Map<String, TaxonInfo> _byLabel;
  final Map<int, TaxonInfo> _byIndex;

  static Future<TaxonomyRepository> loadFromAssets() async {
    final raw = await rootBundle.loadString('assets/data/taxonomy_zh.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawClasses = decoded['classes'] as List<dynamic>;
    final classes = rawClasses
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => TaxonInfo.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.classIndex.compareTo(b.classIndex));

    return TaxonomyRepository._(classes);
  }

  TaxonInfo find(RecognitionPrediction prediction) {
    return _byLabel[prediction.modelLabel] ??
        _byIndex[prediction.classIndex] ??
        TaxonInfo.fallback(
          classIndex: prediction.classIndex,
          modelLabel: prediction.modelLabel,
        );
  }

  List<String> get expectedModelLabels =>
      classes.map((item) => item.modelLabel).toList(growable: false);
}
