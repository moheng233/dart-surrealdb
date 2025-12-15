import 'package:test/test.dart';
import 'package:surrealdb/surrealdb.dart';

void main() {
  group('RecordId', () {
    test('creates RecordId with string id', () {
      final id = RecordId('person', 'john');
      expect(id.table, equals('person'));
      expect(id.id, equals('john'));
      expect(id.toString(), equals('person:john'));
    });

    test('creates RecordId with number id', () {
      final id = RecordId('article', 123);
      expect(id.table, equals('article'));
      expect(id.id, equals(123));
      expect(id.toString(), equals('article:123'));
    });

    test('creates RecordId with List id', () {
      final id = RecordId('person', ['user', '123']);
      expect(id.table, equals('person'));
      expect(id.id, isA<List>());
      expect(id.toString(), equals("person:['user', '123']"));
    });

    test('creates RecordId with Map id', () {
      final id = RecordId('person', {'region': 'us', 'id': '123'});
      expect(id.table, equals('person'));
      expect(id.id, isA<Map>());
      expect(id.toString(), contains('person:{'));
    });

    test('creates RecordId from string', () {
      final id = RecordId.fromString('person:john');
      expect(id.table, equals('person'));
      expect(id.id, equals('john'));
    });
  });

  group('Table', () {
    test('creates Table', () {
      final table = const Table('person');
      expect(table.name, equals('person'));
      expect(table.toString(), equals('person'));
    });

    test('Table equality', () {
      const table1 = Table('person');
      const table2 = Table('person');
      const table3 = Table('article');
      
      expect(table1, equals(table2));
      expect(table1, isNot(equals(table3)));
    });
  });

  group('Duration', () {
    test('creates Duration from string', () {
      const duration = Duration('5s');
      expect(duration.value, equals('5s'));
      expect(duration.toString(), equals('5s'));
    });

    test('creates Duration from factory methods', () {
      final seconds = Duration.fromSeconds(30);
      expect(seconds.value, equals('30s'));

      final minutes = Duration.fromMinutes(5);
      expect(minutes.value, equals('5m'));

      final hours = Duration.fromHours(2);
      expect(hours.value, equals('2h'));
    });
  });

  group('Uuid', () {
    test('creates random Uuid', () {
      final uuid = Uuid();
      expect(uuid.value, isNotEmpty);
      expect(uuid.value.length, equals(36)); // UUID v4 format
    });

    test('creates Uuid with specific value', () {
      final uuid = Uuid('550e8400-e29b-41d4-a716-446655440000');
      expect(uuid.value, equals('550e8400-e29b-41d4-a716-446655440000'));
    });
  });

  group('Geometry', () {
    test('creates GeometryPoint', () {
      const point = GeometryPoint([125.6, 10.1]);
      expect(point.longitude, equals(125.6));
      expect(point.latitude, equals(10.1));
      
      final json = point.toJson();
      expect(json['type'], equals('Point'));
      expect(json['coordinates'], equals([125.6, 10.1]));
    });

    test('creates GeometryLine', () {
      const line = GeometryLine([
        [125.6, 10.1],
        [125.7, 10.2],
      ]);
      
      final json = line.toJson();
      expect(json['type'], equals('LineString'));
      expect(json['coordinates'], hasLength(2));
    });
  });

  group('Errors', () {
    test('creates SurrealDbError', () {
      final error = SurrealDbError('Test error');
      expect(error.message, equals('Test error'));
      expect(error.toString(), contains('Test error'));
    });

    test('creates ConnectionError', () {
      final error = ConnectionError('Connection failed');
      expect(error, isA<SurrealDbError>());
      expect(error.toString(), contains('ConnectionError'));
    });

    test('creates QueryError', () {
      final error = QueryError('Query failed');
      expect(error, isA<SurrealDbError>());
      expect(error.toString(), contains('QueryError'));
    });

    test('creates AuthenticationError', () {
      final error = AuthenticationError('Auth failed');
      expect(error, isA<SurrealDbError>());
      expect(error.toString(), contains('AuthenticationError'));
    });

    test('creates RpcError with code', () {
      final error = RpcError('RPC failed', -32000);
      expect(error, isA<SurrealDbError>());
      expect(error.code, equals(-32000));
      expect(error.toString(), contains('-32000'));
    });
  });
}
