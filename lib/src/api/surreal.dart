import '../engine/engine.dart';
import '../engine/websocket_engine.dart';
import '../engine/http_engine.dart';
import '../errors/errors.dart';
import 'queryable.dart';

/// Options for creating a Surreal instance.
class SurrealOptions {
  /// Custom engine to use (optional)
  final Engine? engine;

  const SurrealOptions({this.engine});
}

/// Main entry point for the SurrealDB SDK.
/// 
/// Provides connection management and access to all database operations.
/// 
/// Example:
/// ```dart
/// final db = Surreal();
/// await db.connect('ws://localhost:8000/rpc');
/// await db.use(namespace: 'test', database: 'test');
/// await db.signin({
///   'username': 'root',
///   'password': 'root',
/// });
/// 
/// final people = await db.select<List>(Table('person'));
/// ```
class Surreal extends Queryable {
  final Engine? _customEngine;

  /// Creates a new Surreal instance.
  /// 
  /// [options] can specify a custom engine.
  Surreal([SurrealOptions? options])
      : _customEngine = options?.engine,
        super(options?.engine ?? WebSocketEngine());

  /// Connects to a SurrealDB instance at the specified URL.
  /// 
  /// Supports the following protocols:
  /// - `ws://` or `wss://` for WebSocket connections
  /// - `http://` or `https://` for HTTP connections
  /// 
  /// Example:
  /// ```dart
  /// await db.connect('ws://localhost:8000/rpc');
  /// ```
  Future<void> connect(String url) async {
    try {
      // If a custom engine was provided, use it
      if (_customEngine != null) {
        await _customEngine!.connect(url);
        return;
      }

      // Otherwise, create appropriate engine based on URL
      Engine newEngine;
      if (url.startsWith('ws://') || url.startsWith('wss://')) {
        newEngine = WebSocketEngine();
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        newEngine = HttpEngine();
      } else {
        throw ArgumentError(
          'Unsupported URL scheme. Use ws://, wss://, http://, or https://',
        );
      }

      // Disconnect old engine if connected
      if (engine.isConnected) {
        await engine.disconnect();
      }

      // Replace the engine
      setEngine(newEngine);
      await newEngine.connect(url);
    } catch (e) {
      if (e is ConnectionError) {
        rethrow;
      }
      throw ConnectionError('Failed to connect to $url', e);
    }
  }

  /// Closes the connection to the SurrealDB instance.
  Future<void> close() async {
    try {
      await engine.disconnect();
    } catch (e) {
      throw ConnectionError('Failed to close connection', e);
    }
  }

  /// Whether the client is currently connected.
  bool get isConnected => engine.isConnected;

  /// Returns the connection URL.
  String? get url => engine.url;
}
