//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, May 06, 2013  5:41:47 PM
// Author: tomyeh
part of entity;

/// Options to access the database.
class AccessOption {
}

/// Used with [load] and [loadIfAny] to indicat the locking
/// is *select-for-share* (i.e., read lock).
final forShare = AccessOption(),
/// Used with [load] and [loadIfAny] to indicat the locking
/// is *select-for-update* (i.e., updatelock).
  forUpdate = AccessOption();

/** An entity which can be stored into an entity store.
 */
abstract class Entity implements Comparable<Entity> {
  /** Instantiates a new entity that is not stored in DB yet.
   * 
   * * [oid] - the OID for this new entity. If omitted, a new OID
   * is generated and assigned.
   */
  Entity({String? oid}): _oid = oid != null ? oid: nextOid(), stored = false;
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
  Entity.be(String oid): _oid = oid, stored = true;

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
  Future? save(Access access, Iterable<String>? fields,
      [void beforeSave(Map data, Set<String>? fields)?]) {

    final fds = fields != null && stored ? _toSet(fields): null;

    final data = HashMap<String, dynamic>();
    write(access.writer, data, fds);
    if (beforeSave != null)
      beforeSave(data, fds);

    if (stored)
      return access.agent.update(this, data, fds);

    //new instance
    stored = true;
    return access.agent.create(this, data);
  }

  /// Deletes this entity.
  ///
  /// - [option] - application-specific option.
  /// Note: it is meaningful only if `access.agent.delete()` supports it.
  Future? delete(Access access, {AccessOption? option}) {
    stored = false;
    return access.agent.delete(this, option);
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
   *     void write(AccessWriter writer, Map data, Set<String> fields) {
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
  void write(AccessWriter writer, Map data, Set<String>? fields) {
    data[fdOtype] = otype;
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
   *     void read(AccessReader reader, Map data, Set<String> fields) {
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
  void read(AccessReader reader, Map data, Set<String>? fields) {
  }

  /// Returns the DB type of the given field, or null if no need to handle
  /// it specially.
  /// 
  /// By default, the database driver will detect the DB type from the object
  /// itself. Thus, in most cases, you don't need to override this method.
  /// However, for databases that can store the same type of objects
  /// in different DB types, you have to override this method.
  /// 
  /// For example, PostgreSQL can store a [List] object as JSON or ARRAY.
  /// If you're using the [postgresql2](https://github.com/tomyeh/postgresql)
  /// driver, the [List] object will be mapped to the ARRAY type.
  /// If it is not what you want, you have to return "json" for
  /// the particular field(s) by overriding this method.
  /// 
  ///     String getDBType(String field) => field == "foo" ? "json": null;
  /// 
  /// > Note: for [postgresql2](https://github.com/tomyeh/postgresql),
  /// > returning "json" or "jsonb" is no difference. They're both encoded
  /// > in the same way.
  String? getDBType(var field) => null;

  ///By default, it returns [oid] when jsonized.
  toJson() => oid;

  @override
  int compareTo(Entity e) => oid.compareTo(e.oid);
  @override
  bool operator==(Object? o) => o is Entity && oid == o.oid;
  @override
  int get hashCode => oid.hashCode;
  @override
  String toString() => oid;
}

/** Indicates the entity is not found.
 */
class EntityException implements Exception {
  final String message;

  EntityException([this.message=""]);
  @override
  String toString() => message;
}

/** Indicates the entity is not found.
 */
class EntityNotFoundException extends EntityException {
  final String oid;

  EntityNotFoundException(this.oid);
  @override
  String toString() => "$oid not found";
}
