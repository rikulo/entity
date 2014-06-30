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
   */
  Entity operator[](String oid);

  /** Loads the data of the given OID.
   * 
   * * [fields] - a collection of fields to load. If null, it means all.
   * If the plugin doesn't support partial load, it can ignore [fields].
   * 
   * Note: it shall return a Future carrying null if not found.
   */
  Future<Map<String, dynamic>> load(Entity entity, [Set<String> fields]);
  /** Updates the entity with the given OID into database.
   *
   * * [data] - the content of the entity. It might contain
   * more fields than what are specified in [fields].
   * And, these fields shall be ignored.
   * * [fields] - the fields to update. If null, all fields in [data]
   * shall be stored.
   */
  Future update(Entity entity, Map<String, dynamic> data, Set<String> fields);
  /** Creates a new entity with the given OID into the database.
   * 
   * * [data] - the content of the entity to store.
   */
  Future create(Entity entity, Map<String, dynamic> data);

  /** Deletes the entity from database.
   */
  Future delete(Entity entity);

  /** The access reader for converting data from what the database returns.
   */
  AccessReader get reader;
  /** The access writer for converting data into what the database accepts.
   */
  AccessWriter get writer;
}

/** A writer for converting data for saving to the database.
 *
 * The plugin can extend it and implement its own converters.
 */
class AccessWriter {
  /** Converts the [DateTime] value.
   *
   * Default: serializes it into an integer (`millisecondsSinceEpoch`).
   */
  dateTime(DateTime value)
    => value != null ? value.millisecondsSinceEpoch: null;

  /** Covnerts the [Entity] instance.
   *
   * Default: serializes it by returning OID.
   */
  entity(Entity value) => value != null ? value.oid: null;
  /** Converts a collection of [Entity] instances.
   *
   * Default: serializes it by returning a list of OID (String).
   */
  entities(Iterable<Entity> value)
    => value != null ? value.map((e) => entity(e)).toList(): null;
  /** Converts a map of [Entity] instances.
   *
   * Default: serializes it by returning a map of OID (String).
   */
  entityMap(Map<dynamic, Entity> value) {
    if (value == null)
      return null;

    final Map<dynamic, String> json = new HashMap();
    for (final key in value.keys)
      json[key] = entity(value[key]);
    return json;
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
   *       toJson() => Write.minify({"some": some, "another": another})
   *     }
   */
  Map<String, dynamic> minify(Map<String, dynamic> json) {
    if (json == null || json.isEmpty)
      return json;

    final Map<String, dynamic> result = new LinkedHashMap();
      //Note: we have to preserve the order since it might be important
      //to the user
    for (final name in json.keys) {
      final value = json[name];
      if (value != null)
        result[name] = value is Map ? minify(value): value;
    }
    return result;
  }
}

/** A reader for converting data read from the database.
 *
 * The plugin can extend it and implement its own converters.
 */
class AccessReader {
  //Parses into [DateTime]
  DateTime dateTime(json)
    => json != null ? new DateTime.fromMillisecondsSinceEpoch(json): null;

  /** Returns the entity of the given OID that was loaded.
   *
   * Note: this method shall not try to load the entity from the database.
   * Rather, it shall get it from a in-memory cache, if supported,
   * which is updated when the corresponding methods of [Access]
   * were called.
   * 
   * Default: it assumes no cache is supported, i.e., it throws
   * throws [UnsupportedError] if [json] is not null and [lenient] is false.
   *
   * * [json] - the json object to convert from. It is actually the OID.
   * * [lenient] - whether *not* to throw an exception if not found.
   * Default: false (i.e., it will throw an exception if not found).
   */
  Entity entity(String json, {bool lenient: false}) {
  	if (json != null && !lenient)
  		throw new UnsupportedError("No cache");
  	return null; //no cache supported
  }

  /** Parses the given collection of OIDs into the corresponding entities.
   *
   * * [lenient] - whether *not* to throw an exception if not found.
   */
  List<Entity> entities(Iterable<String> json, {lenient: false}) {
    if (json == null)
      return null;

    final List entities = [];
    for (final String each in json) {
      final Entity val = entity(each, lenient: lenient);
      if (val != null)
        entities.add(val);
    }
    return entities;
  }
  /** Parses the given map of OIDs into the corresponding entities.
   *
   * * [lenient] - whether *not* to throw an exception if not found.
   */
  Map<dynamic, Entity> entityMap(Map<dynamic, String> json, {lenient: false}) {
    if (json == null)
      return null;

    final Map<dynamic, Entity> entities = new HashMap();
    for (final key in json.keys)
      entities[key] = entity(json[key], lenient: lenient);
    return entities;
  }
}
