import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/recognition_prediction.dart';
import '../models/recognition_record.dart';

abstract interface class HistoryRepository {
  Future<List<RecognitionRecord>> loadAll();

  Future<RecognitionRecord> save({
    required Uint8List imageBytes,
    required List<RecognitionPrediction> predictions,
  });

  Future<void> delete(RecognitionRecord record);

  Future<void> clear();
}

class FileHistoryRepository implements HistoryRepository {
  static const _folderName = 'insect_identifier';
  static const _indexFileName = 'history.json';
  static const _imagesFolderName = 'images';

  final Random _random = Random();

  @override
  Future<List<RecognitionRecord>> loadAll() async {
    final root = await _ensureRootDirectory();
    final indexFile = File(_childPath(root.path, _indexFileName));
    if (!await indexFile.exists()) {
      return const <RecognitionRecord>[];
    }

    try {
      final raw = await indexFile.readAsString();
      final decoded = jsonDecode(raw) as List<dynamic>;
      final records = decoded
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) => RecognitionRecord.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((record) => record.predictions.isNotEmpty)
          .toList();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } on FormatException {
      return const <RecognitionRecord>[];
    } on TypeError {
      return const <RecognitionRecord>[];
    }
  }

  @override
  Future<RecognitionRecord> save({
    required Uint8List imageBytes,
    required List<RecognitionPrediction> predictions,
  }) async {
    final root = await _ensureRootDirectory();
    final imagesDirectory = Directory(_childPath(root.path, _imagesFolderName));
    await imagesDirectory.create(recursive: true);

    final now = DateTime.now();
    final randomSuffix = _random.nextInt(0x7fffffff).toRadixString(16);
    final id = '${now.microsecondsSinceEpoch}_$randomSuffix';
    final extension = _detectImageExtension(imageBytes);
    final imageFile = File(
      _childPath(imagesDirectory.path, '$id$extension'),
    );
    await imageFile.writeAsBytes(imageBytes, flush: true);

    final record = RecognitionRecord(
      id: id,
      createdAt: now,
      imagePath: imageFile.path,
      predictions: List<RecognitionPrediction>.unmodifiable(predictions),
    );

    final records = await loadAll();
    await _writeIndex(root, <RecognitionRecord>[record, ...records]);
    return record;
  }

  @override
  Future<void> delete(RecognitionRecord record) async {
    final root = await _ensureRootDirectory();
    final records = await loadAll();
    final next = records.where((item) => item.id != record.id).toList();

    final imageFile = File(record.imagePath);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }
    await _writeIndex(root, next);
  }

  @override
  Future<void> clear() async {
    final root = await _ensureRootDirectory();
    final imagesDirectory = Directory(_childPath(root.path, _imagesFolderName));
    if (await imagesDirectory.exists()) {
      await imagesDirectory.delete(recursive: true);
    }
    await imagesDirectory.create(recursive: true);
    await _writeIndex(root, const <RecognitionRecord>[]);
  }

  Future<Directory> _ensureRootDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory(_childPath(documents.path, _folderName));
    await root.create(recursive: true);
    return root;
  }

  Future<void> _writeIndex(
    Directory root,
    List<RecognitionRecord> records,
  ) async {
    final indexFile = File(_childPath(root.path, _indexFileName));
    final tempFile = File('${indexFile.path}.tmp');
    final payload = const JsonEncoder.withIndent('  ').convert(
      records.map((record) => record.toJson()).toList(),
    );
    await tempFile.writeAsString(payload, flush: true);
    if (await indexFile.exists()) {
      await indexFile.delete();
    }
    await tempFile.rename(indexFile.path);
  }

  static String _childPath(String parent, String child) {
    return '$parent${Platform.pathSeparator}$child';
  }

  static String _detectImageExtension(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return '.png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return '.jpg';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return '.webp';
    }
    return '.img';
  }
}
