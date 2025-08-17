# Changes

**3.2.0**

* The `data` parameter of `AccessAgent.update` and `AccessAgent.create` must be of type `Map<String, dynamic>`.

**3.1.0**

* The `values` paramter of `PostgresqlAccess.query` and `PostgresqlAccess.execute` must be of type `Map`.

**3.0.1**

* `isValidOid()` introduced the `ignoreLength` argument.

**3.0.0**

* `Entity.write` and `Entity.read` accept `Iterable<String>` as fields instead of `Set<String>`.

**2.8.1**

* `Entity.remove` returns the entity being removed, instead of bool.
* `Access.uncache` returns the entity being removed, instead of void.

**2.7.0**

* `EntityCache.removeWhere` added

**2.6.0**

* `AccessReader.isDateTimeDirectly` and `AccessWriter.isDateTimeDirectly` added

**2.5.2**

* `Entity.oid` becomes mutable.
* Use `Random.secure` to generate OID.

**2.5.0**

* **BREAK CHANGE**
  * `AccessOption` introduced and `forUpdate` and `forShare` are instances of it.
  * Signatures of `Access.load`, `Access.delete`, `load` and `loadIfAny` changed.

**2.1.0**

* `bind_` and `read_` added.
* `oidPattern` added.

**2.0.3**

* `minifyNS` added.

**2.0.1**

* Merged 1.11.0

**2.0.0**

* `AccessReader.entities` and `AccessWriter.entities` will return a list containing non-nullable items only.

**1.11.0**

* `SqlFlavor.deleteFlavor` added

**1.10.1**

* `Entity.toJson()` returns a dynamic type, so the subclass can override with any type.

**1.10.0**

* `Entity.getDBType()` added to override the default handling of a Dart object.

**1.9.0+1**

* `Access.cache()` introduced, so `access.load()` will cache the result.
* `Access.uncache()` introduced, so an app can reload an entity

**1.8.1**

* The `options` argument of `Entity.delete()` can be any type.

**1.8.0**

* `Entity.delete()` supports the `options` argument.

**1.7.0**

* The type of the option argument of `loadIfAny_` is changed to `int`

**1.6.0**

* `SqlFlavor` added for adding `on conflict do nothing` and others to INSERT and UPDATE SQL statements.

**1.5.1**

* `Entity` implements `Comparable<Entity>`
  
**1.5.0+1**

* We allow tilde (`~`) to be used in OID

**1.5.0**

* `Entity.read()` and `Entity.write()` accepts `Map` instead of `Map<String, dynamic>`

**0.9.3**

* `Access.get()` renamed to `Access.fetch()` (avoid using keyword)

**0.9.0**

* `AccessWriter.entityMap` and `AccessReader.entityMap` are removed.
