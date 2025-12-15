/// Base interface for SurrealDB engines.
/// 
/// Engines handle the communication with SurrealDB instances,
/// whether remote (WebSocket, HTTP) or embedded (WASM, Node.js).
abstract class Engine {
  /// Connects to the SurrealDB instance with the given URL.
  Future<void> connect(String url);

  /// Disconnects from the SurrealDB instance.
  Future<void> disconnect();

  /// Executes an RPC method with the given parameters.
  /// 
  /// Returns the result of the RPC call.
  Future<dynamic> rpc(String method, List<dynamic> params);

  /// Whether the engine is currently connected.
  bool get isConnected;

  /// Returns the connection URL.
  String? get url;
}
