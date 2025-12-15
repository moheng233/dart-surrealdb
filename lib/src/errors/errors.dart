/// Base error class for SurrealDB SDK.
class SurrealDbError extends Error {
  /// The error message
  final String message;

  /// Optional error cause
  final Object? cause;

  /// Creates a new SurrealDbError with the given message.
  SurrealDbError(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'SurrealDbError: $message\nCaused by: $cause';
    }
    return 'SurrealDbError: $message';
  }
}

/// Error thrown when connection operations fail.
class ConnectionError extends SurrealDbError {
  ConnectionError(super.message, [super.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'ConnectionError: $message\nCaused by: $cause';
    }
    return 'ConnectionError: $message';
  }
}

/// Error thrown when query operations fail.
class QueryError extends SurrealDbError {
  QueryError(super.message, [super.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'QueryError: $message\nCaused by: $cause';
    }
    return 'QueryError: $message';
  }
}

/// Error thrown when authentication fails.
class AuthenticationError extends SurrealDbError {
  AuthenticationError(super.message, [super.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'AuthenticationError: $message\nCaused by: $cause';
    }
    return 'AuthenticationError: $message';
  }
}

/// Error thrown when engine operations fail.
class EngineError extends SurrealDbError {
  EngineError(super.message, [super.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'EngineError: $message\nCaused by: $cause';
    }
    return 'EngineError: $message';
  }
}

/// Error thrown when RPC operations fail.
class RpcError extends SurrealDbError {
  /// The error code
  final int? code;

  RpcError(super.message, [this.code, super.cause]);

  @override
  String toString() {
    final codeStr = code != null ? ' (code: $code)' : '';
    if (cause != null) {
      return 'RpcError$codeStr: $message\nCaused by: $cause';
    }
    return 'RpcError$codeStr: $message';
  }
}

/// Error thrown when validation fails.
class ValidationError extends SurrealDbError {
  ValidationError(super.message, [super.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'ValidationError: $message\nCaused by: $cause';
    }
    return 'ValidationError: $message';
  }
}
