# Changes

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
