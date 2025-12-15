import 'dart:async';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../errors/errors.dart';
import '../cbor/surreal_cbor.dart';
import 'engine.dart';

/// WebSocket-based engine for remote SurrealDB connections using CBOR.
/// 
/// Uses JSON-RPC 2.0 protocol over WebSocket with CBOR encoding for efficiency.
class WebSocketCborEngine implements Engine {
  WebSocketChannel? _channel;
  String? _url;
  bool _isConnected = false;
  
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  int _requestId = 0;
  StreamSubscription? _subscription;
  
  final SurrealCborEncoder _encoder = SurrealCborEncoder();
  final SurrealCborDecoder _decoder = SurrealCborDecoder();

  @override
  bool get isConnected => _isConnected;

  @override
  String? get url => _url;

  @override
  Future<void> connect(String url) async {
    if (_isConnected) {
      throw ConnectionError('Already connected to $_url');
    }

    try {
      // Ensure URL starts with ws:// or wss://
      if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
        throw ArgumentError('WebSocket URL must start with ws:// or wss://');
      }

      _url = url;
      _channel = WebSocketChannel.connect(
        Uri.parse(url),
        protocols: ['cbor'], // Indicate CBOR support
      );
      
      // Listen for messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      // Wait for first connection state by sending a ping
      try {
        await rpc('ping', []).timeout(const Duration(seconds: 5));
        _isConnected = true;
      } catch (e) {
        await disconnect();
        throw ConnectionError('Failed to establish connection', e);
      }
    } catch (e) {
      if (e is ConnectionError) {
        rethrow;
      }
      throw ConnectionError('Failed to connect to $url', e);
    }
  }

  @override
  Future<void> disconnect() async {
    if (!_isConnected) {
      return;
    }

    try {
      await _subscription?.cancel();
      await _channel?.sink.close();
      _isConnected = false;
      _url = null;
      _channel = null;
      
      // Complete all pending requests with error
      for (final completer in _pendingRequests.values) {
        if (!completer.isCompleted) {
          completer.completeError(
            ConnectionError('Connection closed'),
          );
        }
      }
      _pendingRequests.clear();
    } catch (e) {
      throw ConnectionError('Failed to disconnect', e);
    }
  }

  @override
  Future<dynamic> rpc(String method, List<dynamic> params) async {
    if (!_isConnected || _channel == null) {
      throw ConnectionError('Not connected to any instance');
    }

    final id = '${_requestId++}';
    final completer = Completer<dynamic>();
    _pendingRequests[id] = completer;

    final request = {
      'id': id,
      'method': method,
      'params': params,
    };

    try {
      // Encode request to CBOR
      final cborBytes = _encoder.encode(request);
      _channel!.sink.add(cborBytes);
      
      // Set a timeout for the request
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _pendingRequests.remove(id);
          throw RpcError('Request timeout for method: $method');
        },
      );
    } catch (e) {
      _pendingRequests.remove(id);
      if (e is RpcError) {
        rethrow;
      }
      throw RpcError('RPC call failed: $method', null, e);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      // Decode CBOR message
      final Uint8List bytes;
      if (message is Uint8List) {
        bytes = message;
      } else if (message is List<int>) {
        bytes = Uint8List.fromList(message);
      } else {
        // Ignore non-binary messages
        return;
      }
      
      final data = _decoder.decode(bytes);
      
      if (data is! Map) {
        return;
      }
      
      final id = data['id']?.toString();
      
      if (id == null) {
        // This might be a live query notification
        return;
      }

      final completer = _pendingRequests.remove(id);
      if (completer == null) {
        return;
      }

      if (data.containsKey('error')) {
        final error = data['error'];
        if (error is Map) {
          final code = error['code'] as int?;
          final message = error['message']?.toString() ?? 'Unknown error';
          completer.completeError(RpcError(message, code));
        } else {
          completer.completeError(RpcError(error.toString()));
        }
      } else {
        completer.complete(data['result']);
      }
    } catch (e) {
      // Ignore parsing errors for now
    }
  }

  void _handleError(dynamic error) {
    _isConnected = false;
    
    // Complete all pending requests with error
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(ConnectionError('Connection error', error));
      }
    }
    _pendingRequests.clear();
  }

  void _handleDone() {
    _isConnected = false;
    
    // Complete all pending requests with error
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(ConnectionError('Connection closed'));
      }
    }
    _pendingRequests.clear();
  }
}
