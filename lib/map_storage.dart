//--Map-based Storage Plugin--//
//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Mon, Jun 30, 2014  1:40:00 PM
// Author: tomyeh
library entity.map_storage;

import "dart:async";
import "dart:convert" show json;

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
  
  MapStorageAccess([Map<String, String>? storage])
  : _agent = MapStorageAccessAgent(storage) {
    (reader as CachedAccessReader).cache = _agent._cache;
  }
  MapStorageAccess.by(EntityCache cache, [Map<String, String>? storage])
  : _agent = MapStorageAccessAgent.by(cache, storage) {
    (reader as CachedAccessReader).cache = _agent._cache;
  }

  @override
  T? fetch<T extends Entity>(String? otype, String? oid)
  => _agent._cache.fetch(otype, oid);
  @override
  T cache<T extends Entity>(T entity) => _agent._cache.put(entity);
  @override
  Entity? uncache(String? otype, String? oid)
  => _agent._cache.remove(otype, oid);

  @override
  late final AccessReader reader = CachedAccessReader(_agent._cache);
  @override
  final AccessWriter writer = AccessWriter();

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

  MapStorageAccessAgent([Map<String, String>? storage]):
    this.by(EntityCache(), storage);
  /** Constructs with the given [cache].
   *
   * * [cache] - the cache for storing the entity. It can't be null.
   */
  MapStorageAccessAgent.by(EntityCache cache, [Map<String, String>? storage]):
      _storage = storage ?? {},
      _cache = cache;

  @override
  FutureOr<Map<String, dynamic>?> load(Entity entity, Iterable<String>? fields,
      AccessOption? option) {
    final data = _load(entity.oid);
    if (data != null) {
      assert(data[fdOtype] == entity.otype);
      _cache.put(entity); //update cache
    }
    return Future.value(data);
  }

  Map<String, dynamic>? _load(String oid) {
      final value = _storage[oid];
    if (value != null) {
      final data = json.decode(value);
      assert(data is Map);
      return data as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future? update(Entity entity, Map data, Iterable<String>? fields) {
    final oid = entity.oid;
    if (fields != null) {
      final prevValue = _load(oid);
      if (prevValue == null)
        throw StateError("Not found: $oid");
      for (final fd in fields)
        prevValue[fd] = data[fd];
      data = prevValue;
    }

    _storage[oid] = json.encode(data);
  }

  @override
  Future? create(Entity entity, Map data) {
    final String oid = entity.oid;
    _cache.put(entity);
    _storage[oid] = json.encode(data);
  }

  @override
  Future? delete(Entity entity, AccessOption? option) {
    final String oid = entity.oid;
    _cache.remove(entity.otype, oid);
    _storage.remove(oid);
  }
}
