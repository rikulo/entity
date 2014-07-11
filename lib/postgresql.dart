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
  /** Constructor.
   *
   * * [cache] - whether to enable the cache. Default: true.
   */
  PostgresqlAccess(Connection conn, {bool cache:true}):
      agent = new PostgresqlAccessAgent(conn, cache: cache) {
     (reader as _AccessReader)._cache = _cache;
  }

  @override
  Entity operator[](String oid) => _cache != null ? _cache[oid]: null;

  @override
  final AccessReader reader = new _AccessReader();
  @override
  final AccessWriter writer = new _AccessWriter();
  @override
  final AccessAgent agent;

  ///The connection to the postgreSQL server.
  Connection get conn => (agent as PostgresqlAccessAgent).conn;

  Map<String, Entity> get _cache => (agent as PostgresqlAccessAgent)._cache;

  ///Clear the cache.
  void clearCache() {
    if (_cache != null)
      _cache.clear();
  }
  /** Caches the given entity.
   */
  void cache(Entity entity) {
    if (_cache != null)
      _cache[entity.oid] = entity;
  }
  /** Removes the caching of the entity of the given OID.
   */
  void uncache(String oid) {
    if (_cache != null)
      _cache.remove(oid);
  }
}

/** The agent for accessing PostgreSQL.
 */
class PostgresqlAccessAgent implements AccessAgent {
  ///The connection to the postgreSQL server.
  final Connection conn;
  final Map<String, Entity> _cache;

  PostgresqlAccessAgent(Connection this.conn, {bool cache:true})
  : _cache = cache ? new HashMap(): null;

  @override
  Future<Map<String, dynamic>> load(Entity entity, Set<String> fields,
      option) {
    final StringBuffer sql = new StringBuffer("select ");
    if (fields != null) {
      if (fields.isEmpty) {
        if (option == null)
          throw new ArgumentError("fields");
        fields.add(F_OID); //possible and allowed
      }

      bool first = true;
      for (final String fd in fields) {
        if (first) first = false;
        else sql.write(',');
        sql..write('"')..write(fd)..write('"');
      }
    } else {
      sql.write("*");
    }

    sql..write(' from "')..write(entity.otype)..write('" where "oid"=@oid');
    if (option == FOR_UPDATE)
      sql.write(' for update');
    else if (option == FOR_SHARE)
      sql.write(' for share');

    return conn.query(sql.toString(), {F_OID: entity.oid}).toList()
    .then((List<Row> rows) {
      if (rows.isNotEmpty) {
        assert(rows.length == 1);
        final Row row = rows.first;
        final Map<String, dynamic> data = new HashMap();
        row.forEach((String name, value) => data[name] = value);
        if (_cache != null)
          _cache[entity.oid] = entity; //update cache
        return data;
      }
    });
  }

  @override
  Future update(Entity entity, Map<String, dynamic> data, Set<String> fields) {
    final StringBuffer sql = new  StringBuffer('update "')
      ..write(entity.otype)..write('" set ');
    final Iterable<String> fds = fields == null ? data.keys: fields;

    bool first = true;
    for (final String fd in fds) {
      if (fd == F_OTYPE || fd == F_OID)
        continue;

      if (first) first = false;
      else sql.write(',');
      sql..write('"')..write(fd)..write('"')..write("=@")..write(fd);
    }
    if (first)
      return new Future.value(); //nothing to update

    sql.write(' where "oid"=@oid');
    data[F_OID] = entity.oid;
    return conn.execute(sql.toString(), data);
  }

  @override
  Future create(Entity entity, Map<String, dynamic> data) {
    final StringBuffer sql = new  StringBuffer('insert into "')
      ..write(entity.otype)..write('"("oid"');
    final StringBuffer param = new StringBuffer(" values(@oid");

    for (final String fd in data.keys) {
      if (fd == F_OTYPE || fd == F_OID)
        continue;

      sql..write(',"')..write(fd)..write('"');
      param..write(',@')..write(fd);
    }
    sql.write(')');
    param.write(')');
    data[F_OID] = entity.oid;

    return conn.execute(sql.toString() + param.toString(), data)
    .then((_) {
      if (_cache != null)
        _cache[entity.oid] = entity; //update cache
    });
  }

  @override
  Future delete(Entity entity) {
    return conn.execute(
      'delete from "${entity.otype}" where "oid"=@oid',
      {F_OID: entity.oid})
    .then((_) {
      if (_cache != null)
        _cache.remove(entity.oid); //update cache
    });
  }
}

class _AccessReader extends AccessReader {
  Map<String, Entity> _cache;
  _AccessReader([this._cache]);

  @override
  Entity operator[](String oid) => _cache != null ? _cache[oid]: null;

  @override
  DateTime dateTime(json) => json;
}

class _AccessWriter extends AccessWriter {
  @override
  dateTime(DateTime value) => value;
}
