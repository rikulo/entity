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
  Entity([String oid]): this.oid = oid != null ? oid: nextOid() {
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
  Entity.be(this.oid) {
    stored = true;
  }

  ///The OID.
  final String oid;
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
      [void beforeSave(Entity entity, Map<String, dynamic> data, Set<String> fields)]) {

    final Set<String> fds = fields != null && stored ? _toSet(fields): null;

    final Map<String, dynamic> data = new HashMap();
    write(access.writer, data, fds);
    if (beforeSave != null)
      beforeSave(this, data, fds);

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
   *       data["someEntity"] = writer.entity(someEntity);
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
   *       someEntity = reader.entity(data["someEntity"]);
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
  /** Returns the collection of fields being loaded (never null).
   *
   * > Note: [loadedFields] is maintained by [load] and [loadIfAny].
   * The implementation just needs to declare a data member initialized
   * with an empty set.
   */
  Set<String> get loadedFields;
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
 * * [option] - an option for loading the entity.
 * Technically, you can pass anything that your access provider supports.
 * For SQL, itt could be `null`,
 * [FOR_SHARE] and [FOR_UPDATE]. Default: null (means no lock at all).
 * 
 * It throws [EntityNotFoundException] if the entity is not found
 * (including oid is null).
 */
Future<Entity> load(Access access, String oid,
    Entity newInstance(String oid),
    [Iterable<String> fields, int option])
  => loadIfAny(access, oid, newInstance, fields, option)
  .then((Entity entity) {
    if (entity == null)
      throw new EntityNotFoundException(entity.oid);
    return entity;
  });

/** Loads the entity of the given OID, and return a [Future] carrying
 * null if not found.
 *
 * Please refer to [load] for details.
 */
Future<Entity> loadIfAny(Access access, String oid,
    Entity newInstance(String oid),
    [Iterable<String> fields, int option])
=> loadIfAny_(access, oid, newInstance,
  (Entity entity, Set<String> fields, option)
    => access.agent.load(entity, fields, option),
  fields, option);

///A utility to implement [loadIfAny] and custom load functions.
Future<Entity> loadIfAny_(Access access, String oid,
    Entity newInstance(String oid),
    Future<Map<String, dynamic>> loader(
        Entity entity, Set<String> fields, option),
    Iterable<String> fields, [int option]) {
  if (oid == null)
    return new Future.value();

  Entity entity = access[oid];
  final Entity newEntity = newInstance(oid);
  Set<String> fds;
  if (entity != null && entity.otype == newEntity.otype) {
  //Note: it is possible entity.otype != newEntity.otype if the app tries
  //to load the entity from several tables

    if (option != null) { //we have to go thru [loader] to ensure the lock
      fds = _toSet(fields);

      if (entity is MultiLoad) {
        final Set<String> loaded = (entity as MultiLoad).loadedFields;
        fds = loaded.contains("*") ? new HashSet(): //nothing needed
                fds != null ? fds.difference(loaded): null;
      }
    } else {
      if (entity is! MultiLoad
      || (entity as MultiLoad).loadedFields.contains("*"))
        return new Future.value(entity);

      fds = _toSet(fields);
      if (fds != null) {
        fds = fds.difference((entity as MultiLoad).loadedFields);
        if (fds.isEmpty)
          return new Future.value(entity);
      }
    }
  } else {
    fds = _toSet(fields);
    entity = newEntity;
  }

  return loader(entity, fds, option)
  .then((Map<String, dynamic> data) {
    if (data != null) {
      entity.read(access.reader, data, fds);

      if (entity is MultiLoad) {
        final Set<String> loaded = (entity as MultiLoad).loadedFields;
        if (fds == null)
          loaded.add("*");
        else
          loaded.addAll(fds);
      }
      return entity;
    }
  });
}

Set _toSet(Iterable it) => it is Set || it == null ? it: it.toSet();
