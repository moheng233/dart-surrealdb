/// Represents a record identifier in SurrealDB.
/// 
/// A RecordId consists of a table name and an id, which can be a string,
/// number, list, or object. Example: person:john, article:123, person:['john', 'doe']
class RecordId {
  /// The table name
  final String table;
  
  /// The record id (can be string, number, list, or object)
  final dynamic id;

  /// Creates a new RecordId with the given table and id.
  const RecordId(this.table, this.id);

  /// Creates a RecordId from a string representation (e.g., "person:john")
  factory RecordId.fromString(String str) {
    final parts = str.split(':');
    if (parts.length != 2) {
      throw ArgumentError('Invalid RecordId format: $str');
    }
    return RecordId(parts[0], parts[1]);
  }

  /// Converts the RecordId to its string representation
  @override
  String toString() {
    if (id is String) {
      return '$table:$id';
    } else if (id is num) {
      return '$table:$id';
    } else if (id is List) {
      // For array IDs, convert to JSON-like array format
      final elements = (id as List)
          .map((e) => _valueToString(e))
          .join(', ');
      return '$table:[$elements]';
    } else if (id is Map) {
      // For object IDs, convert to JSON-like format
      final entries = (id as Map).entries
          .map((e) => '${e.key}: ${_valueToString(e.value)}')
          .join(', ');
      return '$table:{$entries}';
    }
    return '$table:$id';
  }

  /// Helper method to convert a value to string representation
  String _valueToString(dynamic value) {
    if (value is String) {
      return "'$value'";
    } else if (value is num || value is bool) {
      return value.toString();
    } else if (value is List) {
      final elements = value.map((e) => _valueToString(e)).join(', ');
      return '[$elements]';
    } else if (value is Map) {
      final entries = value.entries
          .map((e) => '${e.key}: ${_valueToString(e.value)}')
          .join(', ');
      return '{$entries}';
    }
    return value.toString();
  }

  /// Converts to JSON-compatible format
  Map<String, dynamic> toJson() {
    return {
      'tb': table,
      'id': id,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RecordId && 
           other.table == table && 
           other.id == id;
  }

  @override
  int get hashCode => Object.hash(table, id);
}
