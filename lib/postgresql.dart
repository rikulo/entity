//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Mon, Jun 30, 2014  5:51:34 PM
// Author: tomyeh
library entity.postgresql;

import "dart:async";
import "dart:collection" show HashMap;

import "package:postgresql/postgresql.dart" show Connection, Row;

import "entity.dart";

/**
 * The PostgreSQL plugin.
 * 
 * **Note**
 * 
 * 1. It assumes the table name is the same as `Entity.otype`.
 * 2. Each table has a primary key called `oid`.
 * 3. It assumes case-sensitive for the names of tables and columns.
 */
class PostgresqlAccess implements Access {
  final Connection conn;
  final Map<String, Entity> _cache;

  /** Constructor.
   *
   * * [cache] - whether to enable the cache. Default: true.
   */
  PostgresqlAccess(Connection this.conn, {bool cache:true})
  : _cache = cache != null ? new HashMap(): null {
     (reader as _AccessReader)._cache = _cache;
  }

  @override
  Entity operator[](String oid) => _cache != null ? _cache[oid]: null;

  @override
  final AccessReader reader = new _AccessReader();
  @override
  final AccessWriter writer = new _AccessWriter();

  ///Clear the cache.
  void clearCache() {
    if (_cache != null)
      _cache.clear();
  }

  @override
  Future<Map<String, dynamic>> load(Entity entity, [Set<String> fields]) {
    final List<String> query = ["select "];
    if (fields != null) {
      if (fields.isEmpty)
        throw new ArgumentError("fields");

      bool first = true;
      for (final String fd in fields) {
        if (first) first = false;
        else query.add(',');
        query..add('"')..add(fd)..add('"');
      }
    } else {
      query.add("*");
    }
    query..add(' from "')..add(entity.otype)..add('" where "oid"=@oid');
    return conn.query(query.join(''), {F_OID: entity.oid}).toList()
    .then((List<Row> rows) {
      if (rows.isNotEmpty) {
        assert(rows.length == 1);
        final Row row = rows.first;
        final Map<String, dynamic> data = new HashMap();
        row.forEach((String name, value) => data[name] = value);
        return data;
      }
    });
  }

  @override
  Future update(Entity entity, Map<String, dynamic> data, Set<String> fields) {
    final List<String> query = ['update "', entity.otype, '" set '];
    final Iterable<String> fds = fields == null ? data.keys: fields;

    bool first = true;
    for (final String fd in fds) {
      if (fd == F_OTYPE || fd == F_OID)
        continue;

      if (first) first = false;
      else query.add(',');
      query..add('"')..add(fd)..add('"')..add("=@")..add(fd);
    }
    if (first)
      return new Future.value(); //nothing to update

    query.add(' where "oid"=@oid');
    data[F_OID] = entity.oid;
    return conn.execute(query.join(''), data);
  }

  @override
  Future create(Entity entity, Map<String, dynamic> data) {
    final List<String> query = ['insert into "', entity.otype, '"("oid"'];
    final List<String> param = [" values(@oid"];

    for (final String fd in data.keys) {
      if (fd == F_OTYPE || fd == F_OID)
        continue;

      query..add(',"')..add(fd)..add('"');
      param..add(',@')..add(fd);
    }
    query.add(')');
    param.add(')');
    data[F_OID] = entity.oid;
    return conn.execute(query.join('') + param.join(''), data);
  }

  @override
  Future delete(Entity entity) {
    final List<String> query = ['delete from "', entity.otype, '" where "oid"=@oid'];
    return conn.execute(query.join(''), {F_OID: entity.oid});
  }
}

class _AccessReader extends AccessReader {
  Map<String, Entity> _cache;
  _AccessReader([this._cache]);

  @override
  Entity entity(String json, {bool lenient: false}) {
    if (json != null) {
      final Entity entity = _cache != null ? _cache[json]: null;
      if (!lenient && entity == null)
        throw new StateError("Not loaded: $json");
      return entity;
    }
    return null;
  }

  @override
  DateTime dateTime(json) => json;
}

class _AccessWriter extends AccessWriter {
  @override
  dateTime(DateTime value) => value;
}
