// ignore_for_file: avoid_print

import 'package:surrealdb/surrealdb.dart';

/// Example demonstrating CBOR protocol usage with the SurrealDB Dart SDK
/// Note: This example uses print statements for demonstration purposes
void main() async {
  // Create a SurrealDB instance with CBOR enabled
  final db = Surreal(const SurrealOptions(useCbor: true));

  print('=== SurrealDB CBOR Example ===\n');
  print('CBOR enabled: ${db.useCbor}');
  
  // Note: The actual connection would fail without a running SurrealDB instance
  // This is just to demonstrate the API usage
  
  print('\nCBOR Benefits:');
  print('- More efficient binary encoding');
  print('- Smaller message sizes');
  print('- Better performance for large datasets');
  print('- Full support for SurrealDB custom types');
  
  print('\nUsage:');
  print('1. Create Surreal with useCbor: true');
  print('2. Connect and use as normal');
  print('3. All RPC calls use CBOR encoding automatically');
  
  print('\nExample:');
  print('''
  final db = Surreal(const SurrealOptions(useCbor: true));
  await db.connect('ws://localhost:8000/rpc');
  await db.use(namespace: 'test', database: 'test');
  await db.signin({'username': 'root', 'password': 'root'});
  
  // All operations now use CBOR encoding
  final person = await db.create(
    RecordId('person', ['user', '123']),
    {
      'name': 'John',
      'age': 30,
      'created': DateTime.now(),
      'location': const GeometryPoint([125.6, 10.1]),
    },
  );
  ''');
  
  print('\nCBOR vs JSON:');
  print('WebSocket: ws://localhost:8000/rpc (JSON)');
  print('WebSocket: ws://localhost:8000/rpc (CBOR when enabled)');
  print('HTTP:      http://localhost:8000 (JSON)');
  print('HTTP:      http://localhost:8000 (CBOR when enabled)');
  
  // Demonstrate encoding/decoding
  print('\n=== CBOR Encoding/Decoding ===\n');
  
  final encoder = SurrealCborEncoder();
  final decoder = SurrealCborDecoder();
  
  // Example 1: RecordId with composite key
  final recordId = RecordId('person', ['user', '123']);
  final encodedRecord = encoder.encode(recordId);
  print('RecordId encoded size: ${encodedRecord.length} bytes');
  final decodedRecord = decoder.decode(encodedRecord) as RecordId;
  print('RecordId decoded: $decodedRecord');
  
  // Example 2: Complex nested structure
  final complexData = {
    'user': RecordId('person', 'john'),
    'age': 30,
    'active': true,
    'tags': ['dart', 'surrealdb', 'cbor'],
    'metadata': {
      'created': DateTime.now(),
      'location': const GeometryPoint([125.6, 10.1]),
      'duration': const Duration('5m'),
    },
  };
  
  final encodedComplex = encoder.encode(complexData);
  print('\nComplex data encoded size: ${encodedComplex.length} bytes');
  print('(JSON would be larger)');
  
  final decodedComplex = decoder.decode(encodedComplex) as Map;
  print('Decoded user: ${decodedComplex['user']}');
  print('Decoded tags: ${decodedComplex['tags']}');
  
  print('\n=== CBOR Protocol Complete ===');
}
