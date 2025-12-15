import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../errors/errors.dart';
import 'engine.dart';

/// WebSocket-based engine for remote SurrealDB connections.
/// 
/// Uses JSON-RPC 2.0 protocol over WebSocket for bidirectional communication.
class WebSocketEngine implements Engine {
  WebSocketChannel? _channel;
  String? _url;
  bool _isConnected = false;
  
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  int _requestId = 0;
  StreamSubscription? _subscription;

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
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      // Listen for messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      // Wait a bit to ensure connection is established
      await Future.delayed(const Duration(milliseconds: 100));
      
      _isConnected = true;
    } catch (e) {
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
      _channel!.sink.add(jsonEncode(request));
      
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
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final id = data['id'] as String?;
      
      if (id == null) {
        // This might be a live query notification
        return;
      }

      final completer = _pendingRequests.remove(id);
      if (completer == null) {
        return;
      }

      if (data.containsKey('error')) {
        final error = data['error'] as Map<String, dynamic>;
        final code = error['code'] as int?;
        final message = error['message'] as String? ?? 'Unknown error';
        completer.completeError(RpcError(message, code));
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
