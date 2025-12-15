import 'package:test/test.dart';
import 'package:surrealdb/surrealdb.dart';
import 'dart:typed_data';

void main() {
  group('SurrealCborEncoder', () {
    late SurrealCborEncoder encoder;

    setUp(() {
      encoder = SurrealCborEncoder();
    });

    test('encodes null', () {
      final bytes = encoder.encode(null);
      expect(bytes, isNotEmpty);
    });

    test('encodes bool', () {
      final trueBytes = encoder.encode(true);
      final falseBytes = encoder.encode(false);
      expect(trueBytes, isNotEmpty);
      expect(falseBytes, isNotEmpty);
    });

    test('encodes int', () {
      final bytes = encoder.encode(42);
      expect(bytes, isNotEmpty);
    });

    test('encodes double', () {
      final bytes = encoder.encode(3.14);
      expect(bytes, isNotEmpty);
    });

    test('encodes string', () {
      final bytes = encoder.encode('hello');
      expect(bytes, isNotEmpty);
    });

    test('encodes list', () {
      final bytes = encoder.encode([1, 2, 3]);
      expect(bytes, isNotEmpty);
    });

    test('encodes map', () {
      final bytes = encoder.encode({'key': 'value'});
      expect(bytes, isNotEmpty);
    });

    test('encodes RecordId with string id', () {
      final recordId = RecordId('person', 'john');
      final bytes = encoder.encode(recordId);
      expect(bytes, isNotEmpty);
    });

    test('encodes RecordId with number id', () {
      final recordId = RecordId('article', 123);
      final bytes = encoder.encode(recordId);
      expect(bytes, isNotEmpty);
    });

    test('encodes RecordId with List id', () {
      final recordId = RecordId('person', ['user', '123']);
      final bytes = encoder.encode(recordId);
      expect(bytes, isNotEmpty);
    });

    test('encodes Table', () {
      const table = Table('person');
      final bytes = encoder.encode(table);
      expect(bytes, isNotEmpty);
    });

    test('encodes Duration', () {
      const duration = Duration('5s');
      final bytes = encoder.encode(duration);
      expect(bytes, isNotEmpty);
    });

    test('encodes Uuid', () {
      final uuid = Uuid('550e8400-e29b-41d4-a716-446655440000');
      final bytes = encoder.encode(uuid);
      expect(bytes, isNotEmpty);
    });

    test('encodes GeometryPoint', () {
      const point = GeometryPoint([125.6, 10.1]);
      final bytes = encoder.encode(point);
      expect(bytes, isNotEmpty);
    });

    test('encodes DateTime', () {
      final dateTime = DateTime(2023, 12, 15);
      final bytes = encoder.encode(dateTime);
      expect(bytes, isNotEmpty);
    });

    test('encodes complex nested structure', () {
      final data = {
        'user': RecordId('person', 'john'),
        'age': 30,
        'active': true,
        'tags': ['dart', 'surrealdb'],
        'metadata': {
          'created': DateTime(2023, 1, 1),
          'table': const Table('users'),
        },
      };
      final bytes = encoder.encode(data);
      expect(bytes, isNotEmpty);
    });
  });

  group('SurrealCborDecoder', () {
    late SurrealCborEncoder encoder;
    late SurrealCborDecoder decoder;

    setUp(() {
      encoder = SurrealCborEncoder();
      decoder = SurrealCborDecoder();
    });

    test('decodes null', () {
      final bytes = encoder.encode(null);
      final decoded = decoder.decode(bytes);
      expect(decoded, isNull);
    });

    test('decodes bool', () {
      final trueBytes = encoder.encode(true);
      final falseBytes = encoder.encode(false);
      expect(decoder.decode(trueBytes), isTrue);
      expect(decoder.decode(falseBytes), isFalse);
    });

    test('decodes int', () {
      final bytes = encoder.encode(42);
      final decoded = decoder.decode(bytes);
      expect(decoded, equals(42));
    });

    test('decodes double', () {
      final bytes = encoder.encode(3.14);
      final decoded = decoder.decode(bytes);
      expect(decoded, closeTo(3.14, 0.01));
    });

    test('decodes string', () {
      final bytes = encoder.encode('hello');
      final decoded = decoder.decode(bytes);
      expect(decoded, equals('hello'));
    });

    test('decodes list', () {
      final bytes = encoder.encode([1, 2, 3]);
      final decoded = decoder.decode(bytes);
      expect(decoded, equals([1, 2, 3]));
    });

    test('decodes map', () {
      final bytes = encoder.encode({'key': 'value'});
      final decoded = decoder.decode(bytes);
      expect(decoded, equals({'key': 'value'}));
    });

    test('round-trips RecordId with string id', () {
      final recordId = RecordId('person', 'john');
      final bytes = encoder.encode(recordId);
      final decoded = decoder.decode(bytes);
      
      expect(decoded, isA<RecordId>());
      final decodedRecord = decoded as RecordId;
      expect(decodedRecord.table, equals('person'));
      expect(decodedRecord.id, equals('john'));
    });

    test('round-trips RecordId with number id', () {
      final recordId = RecordId('article', 123);
      final bytes = encoder.encode(recordId);
      final decoded = decoder.decode(bytes);
      
      expect(decoded, isA<RecordId>());
      final decodedRecord = decoded as RecordId;
      expect(decodedRecord.table, equals('article'));
      expect(decodedRecord.id, equals(123));
    });

    test('round-trips Table', () {
      const table = Table('person');
      final bytes = encoder.encode(table);
      final decoded = decoder.decode(bytes);
      
      expect(decoded, isA<Table>());
      expect((decoded as Table).name, equals('person'));
    });

    test('round-trips Duration', () {
      const duration = Duration('5s');
      final bytes = encoder.encode(duration);
      final decoded = decoder.decode(bytes);
      
      expect(decoded, isA<Duration>());
      expect((decoded as Duration).value, equals('5s'));
    });

    test('round-trips Uuid', () {
      final uuid = Uuid('550e8400-e29b-41d4-a716-446655440000');
      final bytes = encoder.encode(uuid);
      final decoded = decoder.decode(bytes);
      
      expect(decoded, isA<Uuid>());
      expect((decoded as Uuid).value, equals('550e8400-e29b-41d4-a716-446655440000'));
    });

    test('round-trips GeometryPoint', () {
      const point = GeometryPoint([125.6, 10.1]);
      final bytes = encoder.encode(point);
      final decoded = decoder.decode(bytes);
      
      expect(decoded, isA<GeometryPoint>());
      final decodedPoint = decoded as GeometryPoint;
      expect(decodedPoint.longitude, closeTo(125.6, 0.01));
      expect(decodedPoint.latitude, closeTo(10.1, 0.01));
    });

    test('round-trips DateTime', () {
      final dateTime = DateTime.utc(2023, 12, 15, 10, 30, 0);
      final bytes = encoder.encode(dateTime);
      final decoded = decoder.decode(bytes);
      
      expect(decoded, isA<DateTime>());
      final decodedDateTime = decoded as DateTime;
      expect(decodedDateTime.year, equals(2023));
      expect(decodedDateTime.month, equals(12));
      expect(decodedDateTime.day, equals(15));
    });

    test('round-trips complex nested structure', () {
      final data = {
        'user': RecordId('person', 'john'),
        'age': 30,
        'active': true,
        'tags': ['dart', 'surrealdb'],
      };
      final bytes = encoder.encode(data);
      final decoded = decoder.decode(bytes) as Map;
      
      expect(decoded['user'], isA<RecordId>());
      expect((decoded['user'] as RecordId).table, equals('person'));
      expect((decoded['user'] as RecordId).id, equals('john'));
      expect(decoded['age'], equals(30));
      expect(decoded['active'], isTrue);
      expect(decoded['tags'], equals(['dart', 'surrealdb']));
    });
  });

  group('SurrealOptions with CBOR', () {
    test('creates Surreal with CBOR enabled', () {
      final db = Surreal(const SurrealOptions(useCbor: true));
      expect(db.useCbor, isTrue);
    });

    test('creates Surreal with CBOR disabled by default', () {
      final db = Surreal();
      expect(db.useCbor, isFalse);
    });
  });
}
