import 'dart:convert';
import 'dart:typed_data';
import 'package:cbor/cbor.dart' as cbor;
import '../types/record_id.dart';
import '../types/table.dart';
import '../types/duration.dart';
import '../types/uuid.dart';
import '../types/geometry.dart';

/// CBOR tags for SurrealDB-specific types
class SurrealCborTags {
  /// Tag for RecordId
  static const int recordId = 88;
  
  /// Tag for Table
  static const int table = 89;
  
  /// Tag for Duration
  static const int duration = 90;
  
  /// Tag for UUID
  static const int uuid = 91;
  
  /// Tag for Geometry
  static const int geometry = 92;
  
  /// Tag for DateTime
  static const int dateTime = 93;
}

/// Encodes SurrealDB-specific types to CBOR format
class SurrealCborEncoder {
  /// Encodes a value to CBOR bytes
  Uint8List encode(dynamic value) {
    // Convert to JSON-compatible format first
    final jsonValue = _toJsonCompatible(value);
    
    // Use cbor simple encoder (it's a converter)
    final encoder = cbor.CborSimpleEncoder();
    final encoded = encoder.convert(jsonValue);
    
    return Uint8List.fromList(encoded);
  }

  dynamic _toJsonCompatible(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is RecordId) {
      return {
        '__type': 'recordid',
        'table': value.table,
        'id': _toJsonCompatible(value.id),
      };
    } else if (value is Table) {
      return {
        '__type': 'table',
        'name': value.name,
      };
    } else if (value is Duration) {
      return {
        '__type': 'duration',
        'value': value.value,
      };
    } else if (value is Uuid) {
      return {
        '__type': 'uuid',
        'value': value.value,
      };
    } else if (value is DateTime) {
      return {
        '__type': 'datetime',
        'value': value.toIso8601String(),
      };
    } else if (value is GeometryPoint ||
               value is GeometryLine ||
               value is GeometryPolygon ||
               value is GeometryMultiPoint ||
               value is GeometryMultiLine ||
               value is GeometryMultiPolygon ||
               value is GeometryCollection) {
      final json = value.toJson();
      return {
        '__type': 'geometry',
        ...json,
      };
    } else if (value is List) {
      return value.map((item) => _toJsonCompatible(item)).toList();
    } else if (value is Map) {
      return value.map((key, val) => MapEntry(
        key.toString(),
        _toJsonCompatible(val),
      ));
    } else {
      // Primitive types
      return value;
    }
  }
}

/// Decodes CBOR format to SurrealDB-specific types
class SurrealCborDecoder {
  /// Decodes CBOR bytes to a Dart value
  dynamic decode(Uint8List bytes) {
    final decoder = cbor.CborSimpleDecoder();
    final decoded = decoder.convert(bytes);
    
    return _fromJsonCompatible(decoded);
  }

  dynamic _fromJsonCompatible(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is Map) {
      final type = value['__type'];
      
      if (type == 'recordid') {
        return RecordId(
          value['table']?.toString() ?? '',
          _fromJsonCompatible(value['id']),
        );
      } else if (type == 'table') {
        return Table(value['name']?.toString() ?? '');
      } else if (type == 'duration') {
        return Duration(value['value']?.toString() ?? '');
      } else if (type == 'uuid') {
        return Uuid(value['value']?.toString() ?? '');
      } else if (type == 'datetime') {
        return DateTime.parse(value['value']?.toString() ?? '');
      } else if (type == 'geometry') {
        return _decodeGeometry(value);
      } else {
        // Regular map
        return value.map((key, val) => MapEntry(
          key.toString(),
          _fromJsonCompatible(val),
        ));
      }
    } else if (value is List) {
      return value.map((item) => _fromJsonCompatible(item)).toList();
    } else {
      return value;
    }
  }

  dynamic _decodeGeometry(Map value) {
    final geoType = value['type']?.toString();
    final coordinates = value['coordinates'];
    
    switch (geoType) {
      case 'Point':
        return GeometryPoint(List<double>.from(coordinates as List));
      case 'LineString':
        return GeometryLine(
          (coordinates as List)
              .map((c) => List<double>.from(c as List))
              .toList(),
        );
      case 'Polygon':
        return GeometryPolygon(
          (coordinates as List)
              .map((ring) => (ring as List)
                  .map((c) => List<double>.from(c as List))
                  .toList())
              .toList(),
        );
      case 'MultiPoint':
        return GeometryMultiPoint(
          (coordinates as List)
              .map((c) => List<double>.from(c as List))
              .toList(),
        );
      case 'MultiLineString':
        return GeometryMultiLine(
          (coordinates as List)
              .map((line) => (line as List)
                  .map((c) => List<double>.from(c as List))
                  .toList())
              .toList(),
        );
      case 'MultiPolygon':
        return GeometryMultiPolygon(
          (coordinates as List)
              .map((polygon) => (polygon as List)
                  .map((ring) => (ring as List)
                      .map((c) => List<double>.from(c as List))
                      .toList())
                  .toList())
              .toList(),
        );
      case 'GeometryCollection':
        final geometries = value['geometries'] as List?;
        return GeometryCollection(
          geometries?.map((g) => _fromJsonCompatible(g)).toList() ?? [],
        );
      default:
        throw FormatException('Unknown geometry type: $geoType');
    }
  }
}
