/// Represents a table reference in SurrealDB.
class Table {
  /// The table name
  final String name;

  /// Creates a new Table reference with the given name.
  const Table(this.name);

  /// Converts the Table to its string representation
  @override
  String toString() {
    return name;
  }

  /// Converts to JSON-compatible format
  String toJson() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Table && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
