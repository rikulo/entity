//Copyright (C) 2020 Potix Corporation. All Rights Reserved.
//History: Wed Feb 26 10:38:31 CST 2020
// Author: tomyeh
part of entity;

/** The interface to decorate [Entity] if it allowed to load
 * into the same entity multiple times (with different fields).
 * 
 * If [Entity] implements [MultiLoad], [load] and [loadIfAny]
 * will check if the required fields are loaded. If not, it will
 * load them from database and put into the same entity.
 * If yes, the entity will be returned directly without consulting
 * database.
 * 
 * On the other hand, if this interface is not implemented,
 * the cached entity, if any, will be returned directly.
 */
abstract class MultiLoad {
  /** Returns the set of fields to load for the given [fields].
   * That is, if the caller would like to load certain fields, they
   * will be passed to this method to retrieve what fields really
   * need to be load. For example, if a field has been loaded before,
   * then it doesn't need be returned.
   * 
   * This method can return an empty set if
   * nothing to load, or null to indicate all fields.
   * 
   * * [fields] - fields the caller'd like to load. If null, it means all.
   */
  Set<String>? getFieldsToLoad(Iterable<String>? fields);
  /** Marks the given [fields] are loaded.
   * If [fields] is null, it means all fields have been loaded.
   */
  void setFieldsLoaded(Iterable<String>? fields);
}

/** Loads the data of the given OID from the storage into the given entity.
 *
 * Note: it will invoke `access[oid]` first to see if there is a cached version.
 * If so, return it directly.
 *
 * * [newInstance] - the method to instantiate the entity for holding
 * the data loaded from database.
 * You usually instantiate it with the `be` constructor (see [Entity.be]).
 * * [fields] - a collection of fields to load.
 * Note: if you'd like to load an expression (aka., virutal column, or
 * calculated column), you can pass `(SQL expression) name`.
 * For example: `(due is not null and who is not null) active`.
 * * [option] - an option for loading the entity.
 * Technically, you can pass anything that your access provider supports.
 * For SQL, itt could be `null`,
 * [forShare] and [forUpdate]. Default: null (means no lock at all).
 * 
 * It throws [EntityNotFoundException] if the entity is not found
 * (including oid is null).
 */
Future<T> load<T extends Entity>(Access access, String oid,
      T newInstance(String oid), [Iterable<String>? fields, int? option]) async {
  final entity = await loadIfAny(access, oid, newInstance, fields, option);
  if (entity == null)
    throw EntityNotFoundException(oid);
  return entity;
}

/** Loads the entity of the given OID, and return a [Future] carrying
 * null if not found.
 *
 * Please refer to [load] for details.
 */
Future<T?> loadIfAny<T extends Entity>(Access access, String? oid,
    T newInstance(String oid), [Iterable<String>? fields, int? option])
=> loadIfAny_(access, oid, newInstance,
  (T entity, Set<String>? fields, int? option)
    => access.agent.load(entity, fields, option),
  fields, option);

/// A utility to implement [loadIfAny] and custom load functions.
/// 
/// * [loader] - a function to load the data back. It must
/// return `Future<Map<String, dynamic>>` or `Map<String, dynamic>`
Future<T?> loadIfAny_<T extends Entity>(Access access, String? oid,
    T newInstance(String oid),
    FutureOr<Map?> loader(T entity, Set<String>? fields, int? option),
    Iterable<String>? fields, [int? option]) async {
  if (oid == null) return null;

  final ei = _fetch<T>(access, newInstance(oid), fields, option),
    entity = ei.first;
  if (ei.second) return entity;

  final fds = ei.third,
    data = await loader(entity, fds, option);
  return data == null ? null: read_(access, entity, data, fds);
}

/// Binds the [data] to the entify with the given [oid].
/// If the entity doesn't exists, it will instantiate one.
///
/// It is a utility for implementation.
T bind_<T extends Entity>(Access access, String oid,
    T newInstance(String oid), Map data, Iterable<String>? fields) {
  final ei = _fetch<T>(access, newInstance(oid), fields),
    entity = ei.first;
  return ei.second ? entity: read_(access, entity, data, ei.third);
}

Trio<T, bool, Set<String>?> _fetch<T extends Entity>(Access access, T entity,
     Iterable<String>? fields, [int? option]) {
  final otype = entity.otype,
    cached = access.fetch(otype, entity.oid);
  Set<String>? fds;
  if (cached == null || cached.otype != otype) {
    fds = _toSet(fields);
    access.cache(entity);
  } else {
    fds = cached is MultiLoad ?
        (cached as MultiLoad).getFieldsToLoad(fields):  _toSet(fields);
    if (fds != null && fds.isEmpty && option == null)
      return Trio(cached as T, true/*done*/, null);
      //Note: if option != null, we have to go thru [loader] to ensure the lock
  }
  return Trio(entity, false, fds);
}

/// Reads properties from [data] into [entity], by calling [Entity.read].
/// It also handles if [entity] implements [MultiLoad].
///
/// It is a utility for implementation.
T read_<T extends Entity>(Access access, T entity, Map data, Set<String>? fields) {
  entity.read(access.reader, data, fields);
  if (entity is MultiLoad)
    (entity as MultiLoad).setFieldsLoaded(fields);
  return entity;
}

Set<T>? _toSet<T>(Iterable<T>? it)
=> it is Set || it == null ? it as Set<T>?: it.toSet();
