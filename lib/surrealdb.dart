/// SurrealDB SDK for Dart
/// 
/// A comprehensive Dart SDK for connecting to and interacting with SurrealDB.
/// Supports both remote connections (WebSocket, HTTP) and provides a type-safe
/// API for database operations.
/// 
/// ## Features
/// 
/// - **Multi-protocol Support**: WebSocket and HTTP connections
/// - **Type-safe API**: Leverage Dart's type system for safer database operations
/// - **CRUD Operations**: Create, Read, Update, Delete with builder patterns
/// - **Authentication**: Signin, signup, and token-based authentication
/// - **Live Queries**: Subscribe to real-time database changes
/// - **Graph Relations**: Create and query graph relationships
/// - **Custom Types**: RecordId, Table, Duration, Geometry, and more
/// 
/// ## Quick Start
/// 
/// ```dart
/// import 'package:surrealdb/surrealdb.dart';
/// 
/// void main() async {
///   // Create a new SurrealDB instance
///   final db = Surreal();
///   
///   // Connect to a SurrealDB instance
///   await db.connect('ws://localhost:8000/rpc');
///   
///   // Select namespace and database
///   await db.use(namespace: 'test', database: 'test');
///   
///   // Authenticate
///   await db.signin({
///     'username': 'root',
///     'password': 'root',
///   });
///   
///   // Create a record
///   final person = await db.create(
///     Table('person'),
///     {
///       'name': 'John Doe',
///       'age': 30,
///     },
///   );
///   
///   // Query records
///   final people = await db.select<List>(Table('person'));
///   print('People: $people');
///   
///   // Close connection
///   await db.close();
/// }
/// ```

// Core API
export 'src/api/surreal.dart';
export 'src/api/queryable.dart';
export 'src/api/session.dart';

// Types
export 'src/types/record_id.dart';
export 'src/types/table.dart';
export 'src/types/duration.dart';
export 'src/types/uuid.dart';
export 'src/types/geometry.dart';

// Errors
export 'src/errors/errors.dart';

// Engine (for advanced usage)
export 'src/engine/engine.dart';
export 'src/engine/websocket_engine.dart';
export 'src/engine/http_engine.dart';
export 'src/engine/websocket_cbor_engine.dart';
export 'src/engine/http_cbor_engine.dart';

// CBOR (for advanced usage)
export 'src/cbor/surreal_cbor.dart';
