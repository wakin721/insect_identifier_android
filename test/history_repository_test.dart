import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insect_identifier/models/recognition_prediction.dart';
import 'package:insect_identifier/repositories/history_repository.dart';

void main() {
  late Directory temporaryDirectory;
  late FileHistoryRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'insect_history_test_',
    );
    repository = FileHistoryRepository(
      documentsDirectoryProvider: () async => temporaryDirectory,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('saved history is cached and remains ordered newest first', () async {
    const predictions = <RecognitionPrediction>[
      RecognitionPrediction(
        classIndex: 0,
        modelLabel: 'Acrida cinerea',
        confidence: .9,
      ),
    ];
    final first = await repository.save(
      imageBytes: Uint8List.fromList(<int>[0xff, 0xd8, 0xff, 0xd9]),
      predictions: predictions,
    );

    final indexFile = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}'
      'insect_identifier${Platform.pathSeparator}history.json',
    );
    await indexFile.writeAsString('temporarily invalid');

    final cached = await repository.loadAll();
    expect(cached.single.id, first.id);

    final second = await repository.save(
      imageBytes: Uint8List.fromList(<int>[0xff, 0xd8, 0xff, 0xd9]),
      predictions: predictions,
    );
    final records = await repository.loadAll();

    expect(records.map((record) => record.id), <String>[second.id, first.id]);
    expect(await indexFile.readAsString(), contains(second.id));
    expect(await File(second.imagePath).exists(), isTrue);
  });
}
