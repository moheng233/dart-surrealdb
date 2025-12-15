import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/errors.dart';
import 'engine.dart';

/// HTTP-based engine for remote SurrealDB connections.
/// 
/// Uses HTTP REST endpoints for request/response communication.
class HttpEngine implements Engine {
  String? _url;
  bool _isConnected = false;
  String? _token;
  String? _namespace;
  String? _database;

  final http.Client _client = http.Client();

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
      // Ensure URL starts with http:// or https://
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw ArgumentError('HTTP URL must start with http:// or https://');
      }

      _url = url;
      
      // Test connection with a ping
      await rpc('ping', []);
      
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

    _isConnected = false;
    _url = null;
    _token = null;
    _namespace = null;
    _database = null;
    _client.close();
  }

  @override
  Future<dynamic> rpc(String method, List<dynamic> params) async {
    if (!_isConnected || _url == null) {
      throw ConnectionError('Not connected to any instance');
    }

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add authentication header if token is set
      if (_token != null) {
        headers['Authorization'] = 'Bearer $_token';
      }

      // Add namespace and database headers if set
      if (_namespace != null) {
        headers['surreal-ns'] = _namespace!;
      }
      if (_database != null) {
        headers['surreal-db'] = _database!;
      }

      final body = jsonEncode({
        'id': '1',
        'method': method,
        'params': params,
      });

      final response = await _client
          .post(
            Uri.parse('$_url/rpc'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data.containsKey('error')) {
          final error = data['error'] as Map<String, dynamic>;
          final code = error['code'] as int?;
          final message = error['message'] as String? ?? 'Unknown error';
          throw RpcError(message, code);
        }
        
        // Update internal state for use/authenticate methods
        _updateInternalState(method, params);
        
        return data['result'];
      } else {
        throw RpcError(
          'HTTP ${response.statusCode}: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is RpcError) {
        rethrow;
      }
      throw RpcError('RPC call failed: $method', null, e);
    }
  }

  void _updateInternalState(String method, List<dynamic> params) {
    // Update internal state based on method calls
    if (method == 'authenticate' && params.isNotEmpty) {
      _token = params[0] as String?;
    } else if (method == 'use' && params.length >= 2) {
      _namespace = params[0] as String?;
      _database = params[1] as String?;
    } else if (method == 'signin' || method == 'signup') {
      // Token will be in the response, handled by the caller
    } else if (method == 'invalidate') {
      _token = null;
    }
  }
}
