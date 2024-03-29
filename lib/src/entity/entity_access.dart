//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Mon, Jun 30, 2014 10:24:58 AM
// Author: tomyeh
part of entity;

/**
 * An access channel, aka., a connection, to a database,
 * such as Couchbase and MySQL.
 * 
 * For ACID databases, an access channel is usually a transaction.
 * 
 * How to instantiate an instance depends on the plugin you use.
 */
abstract class Access {
  /** Returns the entity of the given OID, if it is stored in the cache.
   * It always return null if the plugin doesn't support the cache.
   * 
   * > Note: if cache is supported, it also implies [oid] can identify
   * > an entity uniquely (regardless of what its otype is).
   */
  T? fetch<T extends Entity>(String? otype, String? oid);

  /// Caches the entity.
  /// It returns [entity] directly.
  T cache<T extends Entity>(T entity);

  /// Removes the caching of the entity of the given [otype] and [oid].
  Entity? uncache(String? otype, String? oid);

  /// The access reader for converting data from what the database returns.
  AccessReader get reader;
  /// The access writer for converting data into what the database accepts.
  AccessWriter get writer;

  /** The interface for accessing the storage (aka., database).
   * 
   * This method is called internally and implemented by
   * an access provider. The application rarely need to invoke it.
   */
  AccessAgent get agent;
}

/** An agent for handling [load], [update], [create] and [delete]
 * from/into database.
 * 
 * This interface is called internally and implemented by
 * an access provider. The application rarely need to invoke it.
 */
abstract class AccessAgent {
  /** Loads the data of the given OID.
   * 
   * * [fields] - a collection of fields to load. If null, it means all.
   * If the plugin doesn't support partial load, it can ignore [fields].
   * 
   * Note: it shall return a Future carrying null if not found.
   * 
   * * [option] - an option for loading the entity.
   * It is the option passed from [load] and [loadIfAny].
   * It can be application specific.
   * You can ignore it if not supported.
   * For SQL, it is better to supported `null`, [forShare] and [forUpdate].
   */
  FutureOr<Map?> load(Entity entity, Iterable<String>? fields, AccessOption? option);
  /** Updates the entity with the given OID into database.
   *
   * * [data] - the content of the entity. It might contain
   * more fields than what are specified in [fields].
   * And, these fields shall be ignored.
   * * [fields] - the fields to update. If null, all fields in [data]
   * shall be stored.
   */
  Future? update(Entity entity, Map data, Iterable<String>? fields);
  /** Creates a new entity with the given OID into the database.
   * 
   * * [data] - the content of the entity to store.
   */
  Future? create(Entity entity, Map data);

  /// Deletes the entity from database.
  ///
  /// - [option] - an option for deleting this entity.
  /// It is the option, if any. passed from `access.delete()`.
  /// It is application specific, and not used in most implementations.
  Future? delete(Entity entity, AccessOption? option);
}

/// A writer for converting data for saving to the database.
/// The plugin shall implement its own converters.
class AccessWriter {
  /** Converts the [DateTime] value.
   *
   * Default: serializes it into an integer (`millisecondsSinceEpoch`).
   */
  Object? dateTime(DateTime? value)
  => value != null ? value.millisecondsSinceEpoch: null;

  /// Whether [DateTime] can be saved directly without converting.
  /// If true, it means [dateTime] basically does nothing.
  /// 
  /// For database, it is usually true. For sending via network, it is not.
  bool get isDateTimeDirectly => false;

  /** Covnerts the [Entity] instance.
   *
   * Default: serializes it by returning OID.
   */
  Object? entity(Entity? value) => value != null ? value.oid: null;

  /** Converts a collection of [Entity] instances.
   *
   * Default: serializes it by converting each of them via [entity].
   */
  List? entities<T extends Entity>(Iterable<T?>? value) {
    if (value == null) return null;

    final result = [];
    for (final each in value) {
      final o = entity(each);
      if (o != null) result.add(o);
    }
    return result;
  }
}

/** A reader for converting data read from the database.
 *
 * By default, [dateTime] will convert an integer to [DateTime].
 *
 * The plugin can extend it and implement its own converters.
 */
class AccessReader {
  ///Return the [DateTime] instance representing the JSON value.
  DateTime? dateTime(Object? json)
    => json != null ? DateTime.fromMillisecondsSinceEpoch(json as int): null;

  /// Whether [DateTime] can be read directly without converting.
  /// If true, it means [dateTime] basically does nothing.
  /// 
  /// For database, it is usually true. For sending via network, it is not.
  bool get isDateTimeDirectly => false;

  /** Returns the entity of the given OID, or null if not loaded.
   *
   * Note: this method shall not try to load the entity from the database.
   * Rather, it shall get it from a in-memory cache, if supported.
   * 
   * Default: always returns null.
   */
  T? entity<T extends Entity>(String otype, String? json) => null;

  /** Parses the given collection of OIDs into the corresponding entities.
   *
   * > Note: if OID specified in [json] is not found, it
   * > will be ignored. In other words, the result list can be shorter.
   
   * > For example, assume [json] is `['oidA', null, 'oidB']` and `oidA`
   * > is found while `oidB` is not, then the result is
   * > `[entityA]`.
   *
   * * [facade] - if specified and an entity is not found,
   * it will be invoked to instantiate an entity repreenting the
   * not-found entity. It is useful if an entity is no longer available. 
   */
  List<T>? entities<T extends Entity>(String otype, Iterable<String?>? json,
      {T facade(String oid)?}) {
    if (json == null) return null;

    final entities = <T>[];
    for (final oid in json)
      if (oid != null) {
        final e = entity<T>(otype, oid);
        if (e != null) entities.add(e);
        else if (facade != null) entities.add(facade(oid));
      }
    return entities;
  }
}

/** An extension of [AccessReader] that support a cache.
 */
class CachedAccessReader extends AccessReader {
  EntityCache cache;
  CachedAccessReader(EntityCache this.cache);

  @override
  T? entity<T extends Entity>(String? otype, String? oid)
  => cache.fetch(otype, oid);
}

/** Minimizes the JSON map to be stored into DB or sent over internet
 * by removing the entries whose value is null.
 *
 * It can be useful when implementing a plugin, since you don't have
 * to store the null values (in a key-value-type database).
 *
 * It is also useful if an entity contains a PODO object whose
 * `toJson()` returns a map with several null values, such as
 *
 *     class Inner {
 *       String some;
 *       String another;
 *       toJson() => minify({"some": some, "another": another})
 *     }
 */
Map<K, dynamic>? minify<K>(Map<K, dynamic>? json)
=> json == null ? null: minifyNS(json);

/// A null-safety version of [minify].
Map<K, dynamic> minifyNS<K>(Map<K, dynamic> json) {
  if (json.isEmpty) return json;

  final result = <K, dynamic>{};
    //Note: we have to preserve the order since it might be important
    //to the user
  for (final name in json.keys) {
    final value = json[name];
    if (value != null)
      result[name] = value is Map<K, dynamic> ? minifyNS(value): value;
  }
  return result;
}

/** A cache for storing entities.
 */
abstract class EntityCache {
  factory EntityCache() => _EntityCache();

  /** Gets the entity of the given [otype] and [oid].
   */
  T? fetch<T extends Entity>(String? otype, String? oid);
  /** Caches an entity.
   * Note: it returns [entity]
   */
  T put<T extends Entity>(T entity);

  /** Remove the cache of an entity.
   */
  Entity? remove(String? otype, String? oid);

  /** Clears the whole cache.
   */
  void clear();

  /// Remove the cached entities that satisfy the given [test].
  void removeWhere(bool test(String oid, Entity entity));
}

/** A utility class for storing the pair of [otype] and [oid].
 * It is mainly used as the key for accessing a cache (aka., a map)
 * of entities.
 */
class _CacheKey {
  final String? otype;
  final String? oid;

  _CacheKey(this.otype, this.oid);
  _CacheKey._(String this.otype, String this.oid);

	@override
  int get hashCode => oid.hashCode;
	@override
  bool operator==(Object o) => o is _CacheKey && o.oid == oid && o.otype == otype;
}

class _EntityCache implements EntityCache {
  final Map<_CacheKey, Entity> _cache = {};

  _EntityCache();

  @override
  T? fetch<T extends Entity>(String? otype, String? oid)
  => _cache[_CacheKey(otype, oid)] as T?;

  @override
  T put<T extends Entity>(T entity)
  => _cache[_CacheKey._(entity.otype, entity.oid)] = entity;

  @override
  Entity? remove(String? otype, String? oid)
  => _cache.remove(_CacheKey(otype, oid));

  @override
  void clear() => _cache.clear();

  @override
  void removeWhere(bool test(String oid, Entity entity))
  => _cache.removeWhere((k, e) => test(k.oid!, e));
}
