class TaxonInfo {
  const TaxonInfo({
    required this.classIndex,
    required this.modelLabel,
    required this.commonName,
    required this.scientificName,
    required this.rank,
    required this.rankCn,
    required this.orderCn,
    required this.orderLatin,
    required this.familyCn,
    required this.familyLatin,
    required this.genusCn,
    required this.genusLatin,
    this.note,
  });

  final int classIndex;
  final String modelLabel;
  final String commonName;
  final String scientificName;
  final String rank;
  final String rankCn;
  final String orderCn;
  final String orderLatin;
  final String familyCn;
  final String familyLatin;
  final String genusCn;
  final String genusLatin;
  final String? note;

  factory TaxonInfo.fromJson(Map<String, dynamic> json) {
    return TaxonInfo(
      classIndex: (json['class_index'] as num).toInt(),
      modelLabel: json['model_label'] as String,
      commonName: json['common_name'] as String,
      scientificName: json['scientific_name'] as String,
      rank: json['rank'] as String,
      rankCn: json['rank_cn'] as String,
      orderCn: json['order_cn'] as String,
      orderLatin: json['order_latin'] as String,
      familyCn: json['family_cn'] as String,
      familyLatin: json['family_latin'] as String,
      genusCn: json['genus_cn'] as String,
      genusLatin: json['genus_latin'] as String,
      note: json['note'] as String?,
    );
  }

  factory TaxonInfo.fallback({
    required int classIndex,
    required String modelLabel,
  }) {
    return TaxonInfo(
      classIndex: classIndex,
      modelLabel: modelLabel,
      commonName: modelLabel,
      scientificName: modelLabel,
      rank: 'unknown',
      rankCn: '未收录',
      orderCn: '未收录',
      orderLatin: '—',
      familyCn: '未收录',
      familyLatin: '—',
      genusCn: '未收录',
      genusLatin: '—',
    );
  }

  bool get italicizeScientificName => rank == 'species' || rank == 'genus';

  String get orderDisplay => _joinNames(orderCn, orderLatin);
  String get familyDisplay => _joinNames(familyCn, familyLatin);
  String get genusDisplay => _joinNames(genusCn, genusLatin);

  static String _joinNames(String chinese, String latin) {
    if (latin.isEmpty || latin == '—') {
      return chinese;
    }
    return '$chinese · $latin';
  }
}
