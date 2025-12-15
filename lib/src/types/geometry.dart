/// Represents a geometric point.
class GeometryPoint {
  /// The coordinates in the format [longitude, latitude]
  final List<double> coordinates;

  /// Creates a new GeometryPoint with the given coordinates.
  const GeometryPoint(this.coordinates);

  /// Gets the longitude
  double get longitude => coordinates[0];

  /// Gets the latitude
  double get latitude => coordinates[1];

  /// Converts to GeoJSON format
  Map<String, dynamic> toJson() {
    return {
      'type': 'Point',
      'coordinates': coordinates,
    };
  }

  @override
  String toString() => 'Point(${coordinates.join(', ')})';
}

/// Represents a geometric line.
class GeometryLine {
  /// The coordinates forming the line
  final List<List<double>> coordinates;

  /// Creates a new GeometryLine with the given coordinates.
  const GeometryLine(this.coordinates);

  /// Converts to GeoJSON format
  Map<String, dynamic> toJson() {
    return {
      'type': 'LineString',
      'coordinates': coordinates,
    };
  }

  @override
  String toString() => 'LineString(${coordinates.length} points)';
}

/// Represents a geometric polygon.
class GeometryPolygon {
  /// The coordinates forming the polygon (array of rings)
  final List<List<List<double>>> coordinates;

  /// Creates a new GeometryPolygon with the given coordinates.
  const GeometryPolygon(this.coordinates);

  /// Converts to GeoJSON format
  Map<String, dynamic> toJson() {
    return {
      'type': 'Polygon',
      'coordinates': coordinates,
    };
  }

  @override
  String toString() => 'Polygon(${coordinates.length} rings)';
}

/// Represents a multi-point geometry.
class GeometryMultiPoint {
  /// The array of points
  final List<List<double>> coordinates;

  /// Creates a new GeometryMultiPoint with the given coordinates.
  const GeometryMultiPoint(this.coordinates);

  /// Converts to GeoJSON format
  Map<String, dynamic> toJson() {
    return {
      'type': 'MultiPoint',
      'coordinates': coordinates,
    };
  }

  @override
  String toString() => 'MultiPoint(${coordinates.length} points)';
}

/// Represents a multi-line geometry.
class GeometryMultiLine {
  /// The array of lines
  final List<List<List<double>>> coordinates;

  /// Creates a new GeometryMultiLine with the given coordinates.
  const GeometryMultiLine(this.coordinates);

  /// Converts to GeoJSON format
  Map<String, dynamic> toJson() {
    return {
      'type': 'MultiLineString',
      'coordinates': coordinates,
    };
  }

  @override
  String toString() => 'MultiLineString(${coordinates.length} lines)';
}

/// Represents a multi-polygon geometry.
class GeometryMultiPolygon {
  /// The array of polygons
  final List<List<List<List<double>>>> coordinates;

  /// Creates a new GeometryMultiPolygon with the given coordinates.
  const GeometryMultiPolygon(this.coordinates);

  /// Converts to GeoJSON format
  Map<String, dynamic> toJson() {
    return {
      'type': 'MultiPolygon',
      'coordinates': coordinates,
    };
  }

  @override
  String toString() => 'MultiPolygon(${coordinates.length} polygons)';
}

/// Represents a collection of geometries.
class GeometryCollection {
  /// The array of geometries
  final List<dynamic> geometries;

  /// Creates a new GeometryCollection with the given geometries.
  const GeometryCollection(this.geometries);

  /// Converts to GeoJSON format
  Map<String, dynamic> toJson() {
    return {
      'type': 'GeometryCollection',
      'geometries': geometries.map((dynamic g) {
        if (g is GeometryPoint || 
            g is GeometryLine || 
            g is GeometryPolygon ||
            g is GeometryMultiPoint ||
            g is GeometryMultiLine ||
            g is GeometryMultiPolygon) {
          return g.toJson() as Map<String, dynamic>;
        }
        return g as Map<String, dynamic>;
      }).toList(),
    };
  }

  @override
  String toString() => 'GeometryCollection(${geometries.length} items)';
}
