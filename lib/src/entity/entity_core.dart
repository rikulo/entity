//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, May 06, 2013  5:41:47 PM
// Author: tomyeh
part of entity;

/** Used with [load] and [loadIfAny] to indicat the locking
 * is *select-for-share* (i.e., read lock).
 */
const int FOR_SHARE = 1;
/** Used with [load] and [loadIfAny] to indicat the locking
 * is *select-for-update* (i.e., updatelock).
 */
const int FOR_UPDATE = 2;

/** An entity which can be stored into an entity store.
 */
abstract class Entity {
  /** Instantiates a new entity that is not stored in DB yet.
   * 
   * * [oid] - the OID for this new entity. If omitted, a new OID
   * is generated and assigned.
   */
  Entity({String oid}): _oid = oid != null ? oid: nextOid() {
    stored = false;
  }
  /**
   * Instantiates an entity that will be passed to [Storage.load]
   * for holding the data loaded from database.
   * In short, this constructor instantiates an instance representing
   * an entity stored in DB.
   *
   * Application users shall invoke this constructor only for
   * the `entity` argument of [Storage.load].
   * 
   * Also notice that the data members are not initialized
   * by this constructor.
   * Rather, they will be initialized by [read].
   *
   * The deriving class must provide its own constructor calling back this
   * constructor. For example,
   *
   *      MyEntity.be(String oid): super(oid);
   */
  Entity.be(String oid): _oid = oid {
    stored = true;
  }

  ///The OID.
  String get oid => _oid;
  final String _oid;

  /** The object type.
   *
   * The deriving class must override this method to return the unique type.
   * The value must match the value passed to the *otype* argument of
   * [addLoadAs].
   */
  String get otype;

  /** Whether this entity has been stored into database.
   * It is false if it is loaded from database or [save] was called.
   */
  bool stored;

  /** Saves this entity.
   *
   * * [fields] - a collection of fields to update.
   * If null, all fields (returned by [write]) will be updated.
   *     > Notice: [fields] is meaningful only if [stored] is true.
   *     > In other words, it was ignored if it is a new entity (not-saved-yet)
   * * [beforeSave] - allows the caller to modify the JSON object and fields
   * before saving to the database.
   */
  Future save(Access access, Iterable<String> fields,
      [void beforeSave(Map<String, dynamic> data, Set<String> fields)]) {

    final Set<String> fds = fields != null && stored ? _toSet(fields): null;

    final Map<String, dynamic> data = {};
    write(access.writer, data, fds);
    if (beforeSave != null)
      beforeSave(data, fds);

    if (stored)
      return access.agent.update(this, data, fds);

    //new instance
    stored = true;
    return access.agent.create(this, data);
  }

  /** Deletes this entity.
   */
  Future delete(Access access) {
    stored = false;
    return access.agent.delete(this);
  }

  /** Writes this entity to a JSON object that can be serialized to
   * a JSON string and then stored to DB.
   *
   * Application rarely needs to invoke this method. Rather,
   * it is called automatically when [save] is called.
   *
   * Default: it writes one entry: `otype`.
   *
   * The deriving class must override this method to write all required
   * data members. For example,
   *
   *     void write(AccessWriter writer, Map<String, dynamic> data, Set<String> fields) {
   *       super.write(writer, data, fields);
   *       data["someData"] = someData;
   *       data["someEntity"] = writer.entity(SomeType, someEntity);
   *       data["someDateTime"] = writer.dateTime(someDateTime);
   *       if (fields == null || fields.contains("someComplexField")) //optional but optimize
   *         data["someComplexField"] = writer.entities("someComplexField");
   *     }
   *
   * As shown, you can use utilities in [writer] to convert [Entity]
   * and [DateTime].
   *
   * * [fields] - the fields to update. It is null, all fields have to
   * be output.
   * It is used only for optimizing the performance.
   * The deriving class can ignore this field.
   * In general, you check [fields] only if the field is costly to generate
   * (into [data]).
   */
  void write(AccessWriter writer, Map<String, dynamic> data, Set<String> fields) {
    data[F_OTYPE] = otype;
  }
  /** Reads the given JSON object into the data members of this entity.
   *
   * Application rarely needs to invoke this method.
   * It is used by the plugin to initialize an entity (instantiated by
   * [Entity.be]).
   *
   * Default: does nothing (no fields are parsed and read).
   * 
   * The deriving class must override this method to read all data member
   * stored in [write]. For example,
   *
   *     void read(AccessReader reader, Map<String, dynamic> data, Set<String> fields) {
   *       super.read(reader, data, fields);
   *       someData = data["someData"];
   *       someEntity = reader.entity(SomeType, data["someEntity"]);
   *       someDateTime = reader.dateTime(data["someDateTime"]);
   *     }
   *
   * As shown, you can use utilities in [reader] to convert [Entity]
   * and [DateTime].
   *
   * * [fields] - the fields being loaded. If null, it means all fields.
   * In general, you can ignore this argument (but use [data] instead).
   */
  void read(AccessReader reader, Map<String, dynamic> data, Set<String> fields) {
  }

  ///By default, it returns [oid] when jsonized.
  String toJson() => oid;

  @override
  bool operator==(other) => other is Entity && oid == other.oid;
  @override
  int get hashCode => oid.hashCode;
}

/** Indicates the entity is not found.
 */
class EntityException implements Exception {
  final String message;

  EntityException([this.message=""]);
  String toString() => "$message";
}

/** Indicates the entity is not found.
 */
class EntityNotFoundException extends EntityException {
  final String oid;

  EntityNotFoundException(this.oid);
  String toString() => "$oid not found";
}

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
  Set<String> getFieldsToLoad(Iterable<String> fields);
  /** Marks the given [fields] are loaded.
   * If [fields] is null, it means all fields have been loaded.
   */
  void setFieldsLoaded(Iterable<String> fields);
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
 * [FOR_SHARE] and [FOR_UPDATE]. Default: null (means no lock at all).
 * 
 * It throws [EntityNotFoundException] if the entity is not found
 * (including oid is null).
 */
Future<T> load<T extends Entity, Option>(Access access, String oid,
      T newInstance(String oid),
      [Iterable<String> fields, Option option]) async {
  final T entity = await loadIfAny(access, oid, newInstance, fields, option);
  if (entity == null)
    throw new EntityNotFoundException(entity.oid);
  return entity;
}

/** Loads the entity of the given OID, and return a [Future] carrying
 * null if not found.
 *
 * Please refer to [load] for details.
 */
Future<T> loadIfAny<T extends Entity, Option>(Access access, String oid,
    T newInstance(String oid),
    [Iterable<String> fields, Option option])
=> loadIfAny_(access, oid, newInstance,
  (T entity, Set<String> fields, option)
    => access.agent.load(entity, fields, option),
  fields, option);

/// A utility to implement [loadIfAny] and custom load functions.
/// 
/// * [loader] - a function to load the data back. It must
/// return `Future<Map<String, dynamic>>` or `Map<String, dynamic>`
Future<T> loadIfAny_<T extends Entity, Option>(Access access, String oid,
    T newInstance(String oid),
    FutureOr<Map<String, dynamic>> loader(T entity, Set<String> fields, Option option),
    Iterable<String> fields, [Option option]) async {
  if (oid == null)
    return null;

  final T newEntity = newInstance(oid);
  T entity = access.fetch(newEntity.otype, oid);
  Set<String> fds;
  if (entity == null || entity.otype != newEntity.otype) {
    fds = _toSet(fields);
    entity = newEntity;
  } else {
    fds = entity is MultiLoad ?
        (entity as MultiLoad).getFieldsToLoad(fields):  _toSet(fields);
    if (fds != null && fds.isEmpty && option == null)
        return entity;
        //Note: if option != null, we have to go thru [loader] to ensure the lock
  }

  var data = loader(entity, fds, option);
  if (data is Future) data = await data;
  if (data == null) return null;

  entity.read(access.reader, data, fds);
  if (entity is MultiLoad)
    (entity as MultiLoad).setFieldsLoaded(fds);
  return entity;
}

Set<T> _toSet<T>(Iterable<T> it) => it is Set || it == null ? it: it.toSet();
