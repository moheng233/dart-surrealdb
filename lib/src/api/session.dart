import '../engine/engine.dart';
import '../errors/errors.dart';

/// Handles authentication and session state management.
class Session {
  final Engine _engine;
  String? _token;

  Session(this._engine);

  /// Authenticates with username and password.
  /// 
  /// Returns the authentication token.
  Future<String?> signin(Map<String, dynamic> credentials) async {
    try {
      final result = await _engine.rpc('signin', [credentials]);
      
      if (result is String) {
        _token = result;
        return result;
      } else if (result is Map && result.containsKey('token')) {
        _token = result['token'] as String;
        return _token;
      }
      
      return null;
    } catch (e) {
      throw AuthenticationError('Signin failed', e);
    }
  }

  /// Creates a new user account.
  /// 
  /// Returns the authentication token.
  Future<String?> signup(Map<String, dynamic> credentials) async {
    try {
      final result = await _engine.rpc('signup', [credentials]);
      
      if (result is String) {
        _token = result;
        return result;
      } else if (result is Map && result.containsKey('token')) {
        _token = result['token'] as String;
        return _token;
      }
      
      return null;
    } catch (e) {
      throw AuthenticationError('Signup failed', e);
    }
  }

  /// Authenticates with an existing JWT token.
  Future<void> authenticate(String token) async {
    try {
      await _engine.rpc('authenticate', [token]);
      _token = token;
    } catch (e) {
      throw AuthenticationError('Authentication failed', e);
    }
  }

  /// Invalidates the current session.
  Future<void> invalidate() async {
    try {
      await _engine.rpc('invalidate', []);
      _token = null;
    } catch (e) {
      throw AuthenticationError('Invalidation failed', e);
    }
  }

  /// Selects a specific namespace and database.
  Future<void> use({String? namespace, String? database}) async {
    try {
      await _engine.rpc('use', [namespace, database]);
    } catch (e) {
      throw SurrealDbError('Failed to select namespace/database', e);
    }
  }

  /// Gets information about the current session or user.
  Future<Map<String, dynamic>?> info() async {
    try {
      final result = await _engine.rpc('info', []);
      return result as Map<String, dynamic>?;
    } catch (e) {
      throw SurrealDbError('Failed to get session info', e);
    }
  }

  /// Returns the current authentication token.
  String? get token => _token;
}
