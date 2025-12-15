# dart-surrealdb

SurrealDB SDK for Dart - A comprehensive Dart implementation of the SurrealDB client SDK, migrated from the official [surrealdb.js](https://github.com/surrealdb/surrealdb.js) library.

## Features

- 🚀 **Multi-protocol Support**: WebSocket and HTTP connections to remote SurrealDB instances
- 🔒 **Type-safe API**: Leverage Dart's strong type system for safer database operations
- 📝 **CRUD Operations**: Create, Read, Update, Delete with intuitive builder patterns
- 🔐 **Authentication**: Signin, signup, and token-based authentication
- ⚡ **Live Queries**: Subscribe to real-time database changes (WebSocket only)
- 🕸️ **Graph Relations**: Create and query graph relationships
- 🎯 **Custom Types**: RecordId, Table, Duration, Geometry, UUID, and more
- 🛠️ **Error Handling**: Comprehensive error classes for different scenarios
- ⚙️ **CBOR Protocol**: Optional binary encoding for improved performance and efficiency

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  surrealdb: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Quick Start

```dart
import 'package:surrealdb/surrealdb.dart';

void main() async {
  // Create a new SurrealDB instance
  final db = Surreal();
  
  // Connect to a SurrealDB instance
  await db.connect('ws://localhost:8000/rpc');
  
  // Select namespace and database
  await db.use(namespace: 'test', database: 'test');
  
  // Authenticate
  await db.signin({
    'username': 'root',
    'password': 'root',
  });
  
  // Create a record
  final person = await db.create(
    Table('person'),
    {
      'name': 'John Doe',
      'age': 30,
    },
  );
  
  // Query records
  final people = await db.select<List>(Table('person'));
  print('People: $people');
  
  // Close connection
  await db.close();
}
```

## Documentation

### Connection

The SDK supports WebSocket and HTTP protocols:

```dart
// WebSocket connection (recommended for real-time features)
await db.connect('ws://localhost:8000/rpc');
await db.connect('wss://cloud.surrealdb.com/rpc'); // Secure WebSocket

// HTTP connection
await db.connect('http://localhost:8000');
await db.connect('https://cloud.surrealdb.com'); // Secure HTTP
```

### CBOR Protocol (Binary Encoding)

For improved performance and reduced bandwidth usage, enable CBOR encoding:

```dart
// Create instance with CBOR enabled
final db = Surreal(const SurrealOptions(useCbor: true));
await db.connect('ws://localhost:8000/rpc');

// All RPC calls will now use efficient CBOR binary encoding
// Benefits:
// - Smaller message sizes (reduced bandwidth)
// - Faster serialization/deserialization
// - Full support for SurrealDB custom types
```

CBOR is particularly beneficial for:
- Applications with large data transfers
- High-frequency operations
- Limited bandwidth environments
- Embedded systems or mobile apps

### Authentication

```dart
// Sign in with root credentials
await db.signin({
  'username': 'root',
  'password': 'root',
});

// Sign in with namespace credentials
await db.signin({
  'namespace': 'test',
  'username': 'user',
  'password': 'pass',
});

// Sign in with database credentials
await db.signin({
  'namespace': 'test',
  'database': 'test',
  'username': 'user',
  'password': 'pass',
});

// Sign up a new user
await db.signup({
  'namespace': 'test',
  'database': 'test',
  'scope': 'user',
  'email': 'user@example.com',
  'password': 'password',
});

// Authenticate with a token
await db.authenticate('your-jwt-token');

// Invalidate session
await db.invalidate();
```

### CRUD Operations

#### Create

```dart
// Create with auto-generated ID
final person = await db.create(
  Table('person'),
  {
    'name': 'Jane Doe',
    'age': 25,
  },
);

// Create with specific ID
final record = await db.create(
  RecordId('person', 'jane'),
  {
    'name': 'Jane Doe',
    'age': 25,
  },
);

// Create with composite ID (List)
final composite = await db.create(
  RecordId('person', ['user', '123']),
  {
    'name': 'Composite User',
    'age': 30,
  },
);
```

#### Read (Select)

```dart
// Select all records from a table
final people = await db.select<List>(Table('person'));

// Select a specific record
final person = await db.select(RecordId('person', 'jane'));
```

#### Update

```dart
// Merge data into a record
final updated = await db.update(RecordId('person', 'jane')).merge({
  'age': 26,
});

// Replace record content
final replaced = await db.update(RecordId('person', 'jane')).content({
  'name': 'Jane Smith',
  'age': 27,
});

// Apply JSON patches
final patched = await db.update(RecordId('person', 'jane')).patch([
  {
    'op': 'replace',
    'path': '/age',
    'value': 28,
  },
]);
```

#### Delete

```dart
// Delete a specific record
final deleted = await db.delete(RecordId('person', 'jane'));

// Delete all records from a table
final allDeleted = await db.delete(Table('person'));
```

### Raw Queries

Execute custom SurrealQL queries:

```dart
// Simple query
final result = await db.query('SELECT * FROM person');

// Query with parameters
final filtered = await db.query(
  'SELECT * FROM person WHERE age > \$minAge',
  {'minAge': 18},
);

// Multiple statements
final multi = await db.query('''
  CREATE person:john SET name = 'John', age = 30;
  CREATE person:jane SET name = 'Jane', age = 25;
  SELECT * FROM person;
''');

// Access results
final people = multi.get<List>(2); // Get third result (0-indexed)
final allResults = multi.collect(); // Get all results as list
```

### Graph Relations

Create and query relationships between records:

```dart
// Create a relation
final relation = await db.relate(
  RecordId('person', 'john'),
  'knows',
  RecordId('person', 'jane'),
  {
    'since': '2020-01-01',
    'strength': 'strong',
  },
);

// Query with graph traversal
final friends = await db.query(
  'SELECT * FROM person:john->knows->person',
);
```

### Live Queries

Subscribe to real-time changes (WebSocket only):

```dart
// Start a live query
final queryId = await db.live(Table('person'));

// In a real application, you would listen to WebSocket messages
// to receive updates about CREATE, UPDATE, DELETE actions

// Stop the live query
await db.kill(queryId);
```

### Types

The SDK provides several custom types for SurrealDB values:

```dart
// RecordId - represents a record identifier
final id1 = RecordId('person', 'john');
final id2 = RecordId('person', 123);
final id3 = RecordId('person', ['user', '456']); // Composite ID
final id4 = RecordId('person', {'region': 'us', 'id': '789'}); // Object ID

// Table - represents a table reference
final table = Table('person');

// Duration - represents time durations
final duration1 = Duration.fromSeconds(30);
final duration2 = Duration.fromMinutes(5);
final duration3 = Duration('2h30m');

// UUID - represents universally unique identifiers
final uuid1 = Uuid(); // Auto-generated v4
final uuid2 = Uuid('550e8400-e29b-41d4-a716-446655440000');

// Geometry - represents geospatial data
final point = GeometryPoint([125.6, 10.1]); // longitude, latitude
final line = GeometryLine([
  [125.6, 10.1],
  [125.7, 10.2],
]);
final polygon = GeometryPolygon([
  [
    [125.6, 10.1],
    [125.7, 10.1],
    [125.7, 10.2],
    [125.6, 10.2],
    [125.6, 10.1],
  ],
]);
```

### Error Handling

The SDK provides specific error types for different scenarios:

```dart
try {
  await db.connect('ws://localhost:8000/rpc');
} on ConnectionError catch (e) {
  print('Connection failed: ${e.message}');
} on AuthenticationError catch (e) {
  print('Authentication failed: ${e.message}');
} on QueryError catch (e) {
  print('Query failed: ${e.message}');
} on RpcError catch (e) {
  print('RPC error ${e.code}: ${e.message}');
} on SurrealDbError catch (e) {
  print('SurrealDB error: ${e.message}');
}
```

## Architecture

This Dart SDK is a faithful migration of the official JavaScript SDK. For detailed information about the original implementation and architecture, see [SURREALDB_JS_ARCHITECTURE.md](SURREALDB_JS_ARCHITECTURE.md).

### Key Components

- **Surreal**: Main client class for connection management
- **Session**: Handles authentication and session state
- **Queryable**: Provides query interface and CRUD operations
- **Engine**: Abstract interface for different connection protocols
  - **WebSocketEngine**: WebSocket-based communication (JSON-RPC 2.0)
  - **HttpEngine**: HTTP-based communication (REST)

## Migration from JavaScript

If you're familiar with the JavaScript SDK, here are the key differences:

| JavaScript | Dart | Notes |
|------------|------|-------|
| `new Surreal()` | `Surreal()` | Constructor syntax |
| `db.connect(url)` | `await db.connect(url)` | Async/await |
| Arrow functions | Anonymous functions | Dart syntax |
| Promises | Futures | Async handling |
| `const` / `let` | `final` / `var` | Variable declaration |
| Template literals | String interpolation | `'${variable}'` |

## Examples

Check the [example](example/) directory for more usage examples:

- [basic_usage.dart](example/basic_usage.dart) - Comprehensive example showing all major features

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## References

- [SurrealDB Official Website](https://surrealdb.com)
- [SurrealDB Documentation](https://surrealdb.com/docs)
- [SurrealDB JavaScript SDK](https://github.com/surrealdb/surrealdb.js)
- [JavaScript SDK Documentation](https://surrealdb.com/docs/sdk/javascript)

## Acknowledgments

This SDK is a Dart migration of the official [surrealdb.js](https://github.com/surrealdb/surrealdb.js) library, maintaining feature parity and API compatibility where possible while leveraging Dart's strengths in type safety and async programming.
