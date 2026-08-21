import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/objective_extractor.dart';

String reply(String payload) =>
    'TEXT: Aquí tiene.\nTRANS: Here you go.\nGRAMMAR: Polite handover.\n'
    '${ObjectiveExtractor.marker}\n$payload';

void main() {
  group('ObjectiveExtractor.extract', () {
    test('passes a reply without the marker through untouched', () {
      const raw = 'TEXT: Hola.\nTRANS: Hello.\nGRAMMAR: A greeting.';
      final result = ObjectiveExtractor.extract(raw);

      expect(result.content, equals(raw));
      expect(result.objectiveIds, isEmpty);
    });

    test('parses ids and strips the block from the visible content', () {
      final result = ObjectiveExtractor.extract(reply('["order","price"]'));

      expect(result.objectiveIds, equals(['order', 'price']));
      expect(result.content, isNot(contains(ObjectiveExtractor.marker)));
      expect(result.content, isNot(contains('order')));
    });

    test('tolerates a markdown-fenced payload', () {
      final result =
          ObjectiveExtractor.extract(reply('```json\n["order"]\n```'));

      expect(result.objectiveIds, equals(['order']));
    });

    test('an empty array yields no ids', () {
      final result = ObjectiveExtractor.extract(reply('[]'));

      expect(result.objectiveIds, isEmpty);
      expect(result.content, isNot(contains(ObjectiveExtractor.marker)));
    });

    test('lowercases and de-duplicates', () {
      final result =
          ObjectiveExtractor.extract(reply('["Order","order","ORDER"]'));

      expect(result.objectiveIds, equals(['order']));
    });
  });

  group('ObjectiveExtractor.extract - malformed payloads', () {
    test('still strips the block when the JSON is truncated', () {
      final result = ObjectiveExtractor.extract(reply('["order",'));

      expect(result.content, isNot(contains(ObjectiveExtractor.marker)));
      expect(result.content, isNot(contains('order')));
      expect(result.objectiveIds, isEmpty);
    });

    test('strips a marker with no payload at all', () {
      final result = ObjectiveExtractor.extract(reply(''));

      expect(
        result.content,
        equals('TEXT: Aquí tiene.\nTRANS: Here you go.\nGRAMMAR: '
            'Polite handover.'),
      );
      expect(result.objectiveIds, isEmpty);
    });

    test('rejects a bare object — ids must come as an array', () {
      final result = ObjectiveExtractor.extract(reply('{"id":"order"}'));

      expect(result.objectiveIds, isEmpty);
    });

    test('skips non-string elements rather than throwing', () {
      final result =
          ObjectiveExtractor.extract(reply('[42,null,"price"]'));

      expect(result.objectiveIds, equals(['price']));
    });
  });

  group('ObjectiveExtractor.extract - hardening', () {
    test('rejects ids that are not plain slugs', () {
      final result = ObjectiveExtractor.extract(reply(
          '["order price","order;drop","<script>","órder","order"]'));

      expect(result.objectiveIds, equals(['order']));
    });

    test('rejects an absurdly long id', () {
      final long = 'a' * (ObjectiveExtractor.maxIdLength + 1);
      final result = ObjectiveExtractor.extract(reply('["$long","order"]'));

      expect(result.objectiveIds, equals(['order']));
    });

    test('caps how many objectives one turn can claim', () {
      final payload =
          List.generate(10, (i) => '"obj_$i"').join(',');
      final result = ObjectiveExtractor.extract(reply('[$payload]'));

      expect(result.objectiveIds, hasLength(ObjectiveExtractor.maxIds));
    });
  });
}
