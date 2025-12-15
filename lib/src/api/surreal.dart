import '../engine/engine.dart';
import '../engine/websocket_engine.dart';
import '../engine/http_engine.dart';
import '../engine/websocket_cbor_engine.dart';
import '../engine/http_cbor_engine.dart';
import '../errors/errors.dart';
import 'queryable.dart';

/// Options for creating a Surreal instance.
class SurrealOptions {
  /// Custom engine to use (optional)
  final Engine? engine;
  
  /// Whether to use CBOR encoding (default: false)
  final bool useCbor;

  const SurrealOptions({
    this.engine,
    this.useCbor = false,
  });
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
/// 
/// Example with CBOR:
/// ```dart
/// final db = Surreal(SurrealOptions(useCbor: true));
/// await db.connect('ws://localhost:8000/rpc');
/// ```
class Surreal extends Queryable {
  final Engine? _customEngine;
  final bool _useCbor;

  /// Creates a new Surreal instance.
  /// 
  /// [options] can specify a custom engine or enable CBOR encoding.
  Surreal([SurrealOptions? options])
      : _customEngine = options?.engine,
        _useCbor = options?.useCbor ?? false,
        super(options?.engine ?? WebSocketEngine());

  /// Connects to a SurrealDB instance at the specified URL.
  /// 
  /// Supports the following protocols:
  /// - `ws://` or `wss://` for WebSocket connections
  /// - `http://` or `https://` for HTTP connections
  /// 
  /// If CBOR is enabled, uses CBOR-enabled engines for efficient binary encoding.
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

      // Otherwise, create appropriate engine based on URL and CBOR setting
      Engine newEngine;
      if (url.startsWith('ws://') || url.startsWith('wss://')) {
        newEngine = _useCbor ? WebSocketCborEngine() : WebSocketEngine();
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        newEngine = _useCbor ? HttpCborEngine() : HttpEngine();
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
  
  /// Whether CBOR encoding is enabled.
  bool get useCbor => _useCbor;
}
