import 'package:flutter_test/flutter_test.dart';
import 'package:insect_identifier/services/classification_output_parser.dart';

void main() {
  test('extracts and sorts the top three classification probabilities', () {
    final output = <String, dynamic>{
      'classification': <String, dynamic>{
        'name': 'Acrididae',
        'class': 1,
        'confidence': 0.7,
        'top5': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Acrididae',
            'class': 1,
            'confidence': 0.7,
          },
          <String, dynamic>{
            'name': 'Acrida cinerea',
            'class': 0,
            'confidence': 0.92,
          },
          <String, dynamic>{
            'name': 'Vespidae',
            'class': 18,
            'confidence': 0.51,
          },
          <String, dynamic>{
            'name': 'Apidae',
            'class': 2,
            'confidence': 0.43,
          },
        ],
      },
    };

    final predictions = ClassificationOutputParser.topPredictions(output);

    expect(predictions, hasLength(3));
    expect(predictions[0].modelLabel, 'Acrida cinerea');
    expect(predictions[1].modelLabel, 'Acrididae');
    expect(predictions[2].modelLabel, 'Vespidae');
  });

  test('deduplicates a class and keeps its highest confidence', () {
    final output = <String, dynamic>{
      'classification': <String, dynamic>{
        'top5': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Apidae',
            'class': 2,
            'confidence': 0.4,
          },
          <String, dynamic>{
            'name': 'Apidae',
            'class': 2,
            'confidence': 0.8,
          },
          <String, dynamic>{
            'name': 'Vespidae',
            'class': 18,
            'confidence': 0.6,
          },
        ],
      },
    };

    final predictions = ClassificationOutputParser.topPredictions(output);

    expect(predictions, hasLength(2));
    expect(predictions.first.modelLabel, 'Apidae');
    expect(predictions.first.confidence, 0.8);
  });

  test('falls back to the primary classification result', () {
    final output = <String, dynamic>{
      'classification': <String, dynamic>{
        'name': 'Pieris rapae',
        'class': 13,
        'confidence': 0.73,
      },
    };

    final predictions = ClassificationOutputParser.topPredictions(output);

    expect(predictions, hasLength(1));
    expect(predictions.single.classIndex, 13);
    expect(predictions.single.modelLabel, 'Pieris rapae');
  });

  test('clamps confidence and honors a non-positive limit', () {
    final output = <String, dynamic>{
      'classification': <String, dynamic>{
        'name': 'Syrphidae',
        'class': 16,
        'confidence': 1.4,
      },
    };

    final predictions = ClassificationOutputParser.topPredictions(output);
    final empty = ClassificationOutputParser.topPredictions(output, limit: 0);

    expect(predictions.single.confidence, 1.0);
    expect(empty, isEmpty);
  });
}
