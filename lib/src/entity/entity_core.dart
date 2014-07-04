//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, May 06, 2013  5:41:47 PM
// Author: tomyeh
part of entity;

/** An entity which can be stored into an entity store.
 */
abstract class Entity {
  //Members//
  final DBControl _dbc;

  /** Instantiates a new entity that is not stored in DB yet.
   * 
   * * [oid] - the OID for this new entity. If omitted, a new OID
   * is generated and assigned.
   */
  Entity([String oid]): _dbc = new DBControl(),
      this.oid = oid != null ? oid: nextOid();
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
  Entity.be(this.oid): _dbc = new DBControl() {
    _dbc.stored = true;
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

  ///The DB control for this entity.
  DBControl get dbc => _dbc;

  /** Saves this entity.
   *
   * * [fields] - a collection of fields to update.
   * If null, all fields (returned by [write]) will be updated.
   *     > Notice: [fields] is meaningful only if `dbc.stored` is true.
   *     > In other words, it was ignored if it is a new entity (not-saved-yet)
   * * [beforeSave] - allows the caller to modify the JSON object and fields
   * before saving to the entitystore.
   */
  Future save(Access access, Iterable<String> fields,
      [void beforeSave(Entity entity, Map<String, dynamic> data, Set<String> fields)]) {
    _check();

    final Set<String> fds = fields != null && dbc.stored ? _toSet(fields): null;

    final Map<String, dynamic> data = new HashMap();
    write(access.writer, data, fds);
    if (beforeSave != null)
      beforeSave(this, data, fds);

    if (_dbc.stored)
      return access.update(this, data, fds);

    //new instance
    _dbc.stored = true;
    return access.create(this, data);
  }

  /** Deletes this entity.
   *
   * To know if an entity is deleted, you can check `entity.dbc.deleted`.
   */
  Future delete(Access access) {
    _check();

    _dbc._deleted = true;
    return access.delete(this);
  }

  void _check() {
    if (_dbc._deleted)
      throw new StateError("deleted");
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
   * Default: no fields are parsed and read, except the following
   * special fields:
   * 
   * * `-c`: it set `db.stored` to false (indicating the entity is
   * not stored to database yet)
   *
   * The deriving class must override this method to read all data memeber
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
    if (data.remove("-c") == true) //(dirty) sent from the client for creation
      _dbc.stored = false;
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

/** The DB control for an entity.
 * Each entity has exactly one DB control.
 */
class DBControl {
  bool _deleted = false;

  /** Whether this entity has been stored.
   *
   * It shall be considered as read-only.
   * Don't set it directly, unless you know what're you doing.
   */
  bool stored = false;
  ///Whether this entity has been deleted (i.e., [Entity.delete] was called).
  bool get deleted => _deleted;
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
 * 
 * It throws [EntityNotFoundException] if the entity is not found
 * (including oid is null).
 */
Future<Entity> load(Access access, String oid,
    Entity newInstance(String oid), [Iterable<String> fields])
  => loadIfAny(access, oid, newInstance, fields)
  .then((Entity entity) {
    if (entity == null)
      throw new EntityNotFoundException(entity.oid);
    return entity;
  });

/** Loads the entity of the given OID, and return a [Future] carrying
 * null if not found.
 */
Future<Entity> loadIfAny(Access access, String oid,
    Entity newInstance(String oid), [Iterable<String> fields]) {
  if (oid == null)
    return new Future.value();

  Entity entity = access[oid];
  if (entity != null)
    return new Future.value(entity);

  entity = newInstance(oid);
  final Set<String> fds = _toSet(fields);
  return access.load(entity, fds)
  .then((Map<String, dynamic> data) {
    if (data != null) {
      entity.read(access.reader, data, fds);
      return entity;
    }
  });
}

Set _toSet(Iterable it) => it is Set || it == null ? it: it.toSet();
