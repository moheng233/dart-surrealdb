import 'package:uuid/uuid.dart' as uuid_pkg;

/// Represents a UUID value in SurrealDB.
class Uuid {
  /// The UUID string value
  final String value;

  /// Creates a new Uuid with the given value or generates a new one.
  Uuid([String? value]) : value = value ?? const uuid_pkg.Uuid().v4();

  /// Creates a new random UUID (v4)
  factory Uuid.v4() {
    return Uuid();
  }

  @override
  String toString() {
    return value;
  }

  /// Converts to JSON-compatible format
  String toJson() => value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Uuid && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
