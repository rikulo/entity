# Changes

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
