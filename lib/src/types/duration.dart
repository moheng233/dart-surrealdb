/// Represents a duration value in SurrealDB.
/// 
/// Supports various time units: ns, us, ms, s, m, h, d, w, y
class Duration {
  /// The duration value
  final String value;

  /// Creates a new Duration with the given value string.
  /// 
  /// Examples: "5s", "10m", "2h", "1d", "3w", "1y"
  const Duration(this.value);

  /// Creates a Duration from microseconds
  factory Duration.fromMicroseconds(int microseconds) {
    return Duration('${microseconds}us');
  }

  /// Creates a Duration from milliseconds
  factory Duration.fromMilliseconds(int milliseconds) {
    return Duration('${milliseconds}ms');
  }

  /// Creates a Duration from seconds
  factory Duration.fromSeconds(int seconds) {
    return Duration('${seconds}s');
  }

  /// Creates a Duration from minutes
  factory Duration.fromMinutes(int minutes) {
    return Duration('${minutes}m');
  }

  /// Creates a Duration from hours
  factory Duration.fromHours(int hours) {
    return Duration('${hours}h');
  }

  /// Creates a Duration from days
  factory Duration.fromDays(int days) {
    return Duration('${days}d');
  }

  /// Creates a Duration from weeks
  factory Duration.fromWeeks(int weeks) {
    return Duration('${weeks}w');
  }

  /// Creates a Duration from years
  factory Duration.fromYears(int years) {
    return Duration('${years}y');
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
    return other is Duration && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
