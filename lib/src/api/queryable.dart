import '../engine/engine.dart';
import '../errors/errors.dart';
import '../types/record_id.dart';
import '../types/table.dart';
import 'session.dart';

/// Provides the query interface for database operations.
class Queryable extends Session {
  final Engine _engine;

  Queryable(this._engine) : super(_engine);

  /// Creates a new record in the specified table or resource.
  /// 
  /// [resource] can be a Table or RecordId.
  /// Returns the created record(s).
  Future<T> create<T>(dynamic resource, [Map<String, dynamic>? data]) async {
    try {
      final resourceStr = _resourceToString(resource);
      final result = await engine.rpc('create', [resourceStr, data]);
      return result as T;
    } catch (e) {
      throw QueryError('Create failed', e);
    }
  }

  /// Selects records from the specified table or resource.
  /// 
  /// [resource] can be a Table or RecordId.
  /// Returns the selected record(s).
  Future<T> select<T>(dynamic resource) async {
    try {
      final resourceStr = _resourceToString(resource);
      final result = await engine.rpc('select', [resourceStr]);
      return result as T;
    } catch (e) {
      throw QueryError('Select failed', e);
    }
  }

  /// Updates records in the specified table or resource.
  /// 
  /// [resource] can be a Table or RecordId.
  /// Returns an UpdateBuilder for chaining operations.
  UpdateBuilder<T> update<T>(dynamic resource) {
    return UpdateBuilder<T>(this, resource);
  }

  /// Deletes records from the specified table or resource.
  /// 
  /// [resource] can be a Table or RecordId.
  /// Returns the deleted record(s).
  Future<T> delete<T>(dynamic resource) async {
    try {
      final resourceStr = _resourceToString(resource);
      final result = await engine.rpc('delete', [resourceStr]);
      return result as T;
    } catch (e) {
      throw QueryError('Delete failed', e);
    }
  }

  /// Executes a raw SurrealQL query.
  /// 
  /// [sql] is the SurrealQL query string.
  /// [vars] are optional query parameters.
  /// Returns a QueryResult with the results.
  Future<QueryResult> query(String sql, [Map<String, dynamic>? vars]) async {
    try {
      final result = await engine.rpc('query', [sql, vars ?? {}]);
      return QueryResult(result);
    } catch (e) {
      throw QueryError('Query failed', e);
    }
  }

  /// Executes a raw SurrealQL query and returns raw results.
  /// 
  /// [sql] is the SurrealQL query string.
  /// [vars] are optional query parameters.
  Future<dynamic> queryRaw(String sql, [Map<String, dynamic>? vars]) async {
    try {
      return await engine.rpc('query', [sql, vars ?? {}]);
    } catch (e) {
      throw QueryError('Query failed', e);
    }
  }

  /// Subscribes to live query updates from a table.
  /// 
  /// [table] is the table to subscribe to.
  /// [diff] whether to return diffs instead of full records.
  /// Returns a LiveQuerySubscription.
  Future<String> live(dynamic table, [bool diff = false]) async {
    try {
      final tableStr = _resourceToString(table);
      final result = await engine.rpc('live', [tableStr, diff]);
      return result as String;
    } catch (e) {
      throw QueryError('Live query failed', e);
    }
  }

  /// Stops a live query.
  /// 
  /// [queryId] is the UUID of the live query to stop.
  Future<void> kill(String queryId) async {
    try {
      await engine.rpc('kill', [queryId]);
    } catch (e) {
      throw QueryError('Kill query failed', e);
    }
  }

  /// Creates a graph relation between two records.
  /// 
  /// [from] is the source record.
  /// [relation] is the relation table name.
  /// [to] is the target record.
  /// [data] is optional relation data.
  Future<T> relate<T>(
    dynamic from,
    String relation,
    dynamic to, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      final fromStr = _resourceToString(from);
      final toStr = _resourceToString(to);
      final result = await engine.rpc('relate', [fromStr, relation, toStr, data]);
      return result as T;
    } catch (e) {
      throw QueryError('Relate failed', e);
    }
  }

  /// Gets the underlying engine.
  Engine get engine => _engine;

  String _resourceToString(dynamic resource) {
    if (resource is String) {
      return resource;
    } else if (resource is Table) {
      return resource.toString();
    } else if (resource is RecordId) {
      return resource.toString();
    } else {
      throw ArgumentError('Resource must be a String, Table, or RecordId');
    }
  }
}

/// Builder for update operations.
class UpdateBuilder<T> {
  final Queryable _queryable;
  final dynamic _resource;

  UpdateBuilder(this._queryable, this._resource);

  /// Merges the given data into the record(s).
  Future<T> merge(Map<String, dynamic> data) async {
    try {
      final resourceStr = _queryable._resourceToString(_resource);
      final result = await _queryable.engine.rpc('merge', [resourceStr, data]);
      return result as T;
    } catch (e) {
      throw QueryError('Merge failed', e);
    }
  }

  /// Applies JSON patches to the record(s).
  Future<T> patch(List<Map<String, dynamic>> patches) async {
    try {
      final resourceStr = _queryable._resourceToString(_resource);
      final result = await _queryable.engine.rpc('patch', [resourceStr, patches]);
      return result as T;
    } catch (e) {
      throw QueryError('Patch failed', e);
    }
  }

  /// Replaces the record(s) with the given data.
  Future<T> content(Map<String, dynamic> data) async {
    try {
      final resourceStr = _queryable._resourceToString(_resource);
      final result = await _queryable.engine.rpc('update', [resourceStr, data]);
      return result as T;
    } catch (e) {
      throw QueryError('Update failed', e);
    }
  }
}

/// Result of a query operation.
class QueryResult {
  final dynamic _data;

  QueryResult(this._data);

  /// Gets the result at the specified index.
  T get<T>(int index) {
    if (_data is List) {
      return (_data as List)[index] as T;
    }
    throw QueryError('Result is not a list');
  }

  /// Collects all results into a list.
  List<T> collect<T>() {
    if (_data is List) {
      return (_data as List).cast<T>();
    }
    return [_data as T];
  }

  /// Gets the raw data.
  dynamic get raw => _data;
}
