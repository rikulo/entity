//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Mon, Jun 30, 2014  5:51:34 PM
// Author: tomyeh
part of entity.postgresql;

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
  PostgresqlAccess(Connection this.conn, {bool cache:true}) {
    _agent = PostgresqlAccessAgent(this, cache: cache);
    (reader as _AccessReader)._cache = _cache;
  }

  @override
  T fetch<T extends Entity>(String otype, String oid)
  => _cache != null ? _cache.fetch(otype, oid): null;

  @override
  final AccessReader reader = _AccessReader();
  @override
  final AccessWriter writer = _AccessWriter();
  @override
  AccessAgent get agent => _agent;
  AccessAgent _agent;

  ///The connection to the postgreSQL server.
  final Connection conn;

  EntityCache get _cache => (agent as PostgresqlAccessAgent)._cache;

  /// Queues a command for execution, and when done, returns the number of rows
  /// affected by the SQL command.
  Future<int> execute(String sql, [values]) => conn.execute(sql, values);
  /// Queue a SQL query to be run, returning a [Stream] of rows.
  Stream<Row> query(String sql, [values]) => conn.query(sql, values);

  ///Clear the cache.
  void clearCache() {
    if (_cache != null)
      _cache.clear();
  }
  /** Caches the given entity.
   */
  void cache(Entity entity) {
    if (_cache != null)
      _cache.put(entity);
  }
  /** Removes the caching of the entity of the given [otype] and [oid].
   */
  void uncache(String otype, String oid) {
    if (_cache != null)
      _cache.remove(otype, oid);
  }
}

/** The agent for accessing PostgreSQL.
 */
class PostgresqlAccessAgent implements AccessAgent {
  ///The connection to the postgreSQL server.
  final PostgresqlAccess access;
  final EntityCache _cache;

  PostgresqlAccessAgent(PostgresqlAccess this.access, {bool cache:true})
  : _cache = cache ? EntityCache(): null;
  PostgresqlAccessAgent.by(PostgresqlAccess this.access, EntityCache cache)
  : _cache = cache;

  @override
  Future<Map<String, dynamic>> load<Option>(Entity entity, Set<String> fields,
      Option option) async {
    final StringBuffer sql = StringBuffer("select ");
    if (fields != null) {
      if (fields.isEmpty)
        fields.add(fdOid); //possible and allowed

      bool first = true;
      for (final String fd in fields) {
        if (first) first = false;
        else sql.write(',');

        if (StringUtil.isChar(fd[0], digit: true, match: "("))
          sql.write(fd);
        else
          sql..write('"')..write(fd)..write('"');
      }
    } else {
      sql.write("*");
    }

    sql..write(' from "')..write(entity.otype)..write('" where "oid"=@oid');
    if (option == forUpdate)
      sql.write(' for update');
    else if (option == forShare)
      sql.write(' for share');

    await for(final Row row in access.query(sql.toString(), {fdOid: entity.oid})) {
      final data = HashMap<String, dynamic>();
      row.forEach((String name, value) => data[name] = value);
      if (_cache != null)
        _cache.put(entity); //update cache
      return data;
    }

    return null;
  }

  @override
  Future update(Entity entity, Map<String, dynamic> data, Set<String> fields) {
    final StringBuffer sql = StringBuffer('update "')
      ..write(entity.otype)..write('" set ');
    final Iterable<String> fds = fields == null ? data.keys: fields;

    bool first = true;
    for (final String fd in fds) {
      if (fd == fdOtype || fd == fdOid)
        continue;

      if (first) first = false;
      else sql.write(',');
      sql..write('"')..write(fd)..write('"')..write("=@")..write(fd);

      if (!data.containsKey(fd)) //postgresql driver needs every field
        data[fd] = null;
    }
    if (first)
      return Future.value(); //nothing to update

    sql.write(' where "oid"=@oid');
    data[fdOid] = entity.oid;
    return access.execute(sql.toString(), data);
  }

  @override
  Future create(Entity entity, Map<String, dynamic> data) async {
    final StringBuffer sql = StringBuffer('insert into "')
      ..write(entity.otype)..write('"("oid"');
    final StringBuffer param = StringBuffer(" values(@oid");

    for (final String fd in data.keys) {
      if (fd == fdOtype || fd == fdOid || data[fd] == null)
        continue;

      sql..write(',"')..write(fd)..write('"');
      param..write(',@')..write(fd);
    }
    sql.write(')');
    param.write(')');
    data[fdOid] = entity.oid;

    await access.execute(sql.toString() + param.toString(), data);

    if (_cache != null)
      _cache.put(entity); //update cache
  }

  @override
  Future delete(Entity entity) async {
    await access.execute(
      'delete from "${entity.otype}" where "oid"=@oid',
      {fdOid: entity.oid});

    if (_cache != null)
      _cache.remove(entity.otype, entity.oid); //update cache
  }
}

class _AccessReader extends AccessReader {
  EntityCache _cache; //not final since it might be assigned by caller
  _AccessReader([this._cache]);

  @override
  T entity<T extends Entity>(String otype, String oid)
  => _cache != null ? _cache.fetch(otype, oid): null;

  @override
  DateTime dateTime(json) => json;
}

class _AccessWriter extends AccessWriter {
  @override
  dateTime(DateTime value) => value;
}
