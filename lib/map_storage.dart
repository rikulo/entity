//--Map-based Storage Plugin--//
//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Mon, Jun 30, 2014  1:40:00 PM
// Author: tomyeh
library entity.map_storage;

import "dart:async";
import "dart:convert" show JSON;

import "entity.dart";

/**
 * A map-based storage plugin.
 * You can use it to store entities in a map, `window.localStorage`
 * and `window.sessionStorage`.
 * 
 * Note: this implementation supports cache. It is mainly designed for using
 * on the client. If you don't want, you can pass a dummy [EntityCache] to
 * [MapStorageAccess.by].
 */
class MapStorageAccess implements Access {
  final MapStorageAccessAgent _agent;
  
  MapStorageAccess([Map<String, String> storage])
  : _agent = new MapStorageAccessAgent(storage) {
  	(reader as CachedAccessReader).cache = _agent._cache;
  }
  MapStorageAccess.by(EntityCache cache, [Map<String, String> storage])
  : _agent = new MapStorageAccessAgent.by(cache, storage) {
  	(reader as CachedAccessReader).cache = _agent._cache;
  }

  @override
  T fetch<T extends Entity>(String otype, String oid) => _agent._cache.fetch(otype, oid);

  @override
  final AccessReader reader = new CachedAccessReader();
  @override
  final AccessWriter writer = new AccessWriter();

  @override
  AccessAgent get agent => _agent;

  ///Clear the cache.
  void clearCache() => _agent._cache.clear();
}

/** The access aggent for map-based storage.
 */
class MapStorageAccessAgent implements AccessAgent {
  //The persistent storage.
  final Map<String, String> _storage;
  ///The cached entities.
  final EntityCache _cache;

  MapStorageAccessAgent([Map<String, String> storage]):
    this.by(new EntityCache(), storage);
  /** Constructs with the given [cache].
   *
   * * [cache] - the cache for storing the entity. It can't be null.
   */
  MapStorageAccessAgent.by(EntityCache cache, [Map<String, String> storage]):
      _storage = storage != null ? storage: {},
      _cache = cache;

  @override
  Future<Map<String, dynamic>> load(Entity entity, Set<String> fields,
      option) {
    final Map<String, dynamic> data = _load(entity.oid);
    if (data != null) {
      assert(data[F_OTYPE] == entity.otype);
      _cache.put(entity); //update cache
    }
    return new Future.value(data);
  }

  Map<String, dynamic> _load(String oid) {
    if (oid != null) {
      final String value = _storage[oid];
      if (value != null) {
        final data = JSON.decode(value);
        assert(data is Map);
        return data;
      }
    }
    return null;
  }

  @override
  Future update(Entity entity, Map<String, dynamic> data, Set<String> fields) {
    final String oid = entity.oid;

    if (fields != null) {
      final Map<String, dynamic> prevValue = _load(oid);
      if (prevValue == null)
      	throw new StateError("Not found: $oid");
      for (final String fd in fields)
        prevValue[fd] = data[fd];
      data = prevValue;
    }

    _storage[oid] = JSON.encode(data);
    return new Future.value();
  }

  @override
  Future create(Entity entity, Map<String, dynamic> data) {
    final String oid = entity.oid;
    _cache.put(entity);
    _storage[oid] = JSON.encode(data);
    return new Future.value();
  }

  @override
  Future delete(Entity entity) {
    final String oid = entity.oid;
    _cache.remove(entity.otype, oid);
    _storage.remove(oid);
    return new Future.value();
  }
}
