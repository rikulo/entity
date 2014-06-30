//--Couchbase Plugin--//
//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Mon, Jun 30, 2014 10:34:06 AM
// Author: tomyeh
library entity.couchbase;

import "dart:async";
import "dart:convert" show JSON, UTF8;

import "package:memcached_client/memcached_client.dart"
  show OPStatus, GetResult;
import "package:couchclient/couchclient.dart"
  show CouchClient;

import "entity.dart";

/** An access channel to Couchbase.
 * 
 * Note this implemenation doesn't support cache, since it makes no
 * sense in a clustering environment.
 */
class CouchbaseAccess implements Access {
  final CouchClient client;

  CouchbaseAccess(CouchClient this.client);

  @override
  final AccessReader reader = new AccessReader();
  @override
  final AccessWriter writer = new AccessWriter();

  @override
  Future<Map<String, dynamic>> load(Entity entity, [Set<String> fields]) {
    final String oid = entity.oid;
    return _load(oid)
    .then((Map<String, dynamic> data) {
      if (data != null) {
        assert(data[F_OTYPE] == entity.otype);
        return new Future.value(data);
      }
    });
  }

  Future<Map<String, dynamic>> _load(String oid) {
    if (oid == null)
      return new Future.value();

    return client.get(oid)
    .then((GetResult r) {
      final data = JSON.decode(UTF8.decode(r.data));
      assert(data is Map);
      return data;
    })
    .catchError((ex) => null, test: (ex) => ex == OPStatus.KEY_NOT_FOUND);
  }

  @override
  Future update(Entity entity, Map<String, dynamic> data, Set<String> fields) {
    final String oid = entity.oid;

    if (fields == null)
      return _replace(oid, data);

    return _load(oid)
    .then((Map<String, dynamic> prevValue) {
      if (prevValue == null)
        throw new StateError("Not found: $oid");
      for (final String fd in fields)
        prevValue[fd] = data[fd];

      return _replace(oid, prevValue);
    });
  }
  Future _replace(String oid, Map<String, dynamic> data)
  => client.replace(oid, UTF8.encode(JSON.encode(writer.minify(data))));

  @override
  Future create(Entity entity, Map<String, dynamic> data)
  => client.add(entity.oid, UTF8.encode(JSON.encode(writer.minify(data))));

  @override
  Future delete(Entity entity)
  => client.delete(entity.oid)
  .catchError((ex) => null, test: (ex) => ex == OPStatus.KEY_NOT_FOUND);
}
