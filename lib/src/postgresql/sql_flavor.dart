//Copyright (C) 2020 Potix Corporation. All Rights Reserved.
//History: Wed Feb 26 10:41:23 CST 2020
// Author: tomyeh
part of entity.postgresql2;

/// Use to add additional *flavor* to SQL statement before execution.
/// For example, you can add "on conflict do nothing" as follows.
///
/// ```
/// class YourEntity extends Entity
/// with SqlFlavorMixin implements SqlFlavor {
///  ...
/// }
/// 
/// final e = new YourEntity(...);
/// e.insertFlavor = onConflictDoNothing;
/// e.save(access, null);
/// ```
abstract class SqlFlavor {
  /// A callback to return the adjusted SQL INSERT statement ([sql]).
  String Function(String sql, Map? data)? get insertFlavor;
  /// A callback to return the adjusted SQL UPDATE statement ([sql]).
  String Function(String sql, Map? data)? get updateFlavor;
  /// A callback to return the adjusted SQL DELETE statement ([sql]).
  String Function(String sql, Map? data)? get deleteFlavor;
}

/// A mixin for [SqlFlavor] that allows callers to plug in
/// flavors on demand. For example,
/// 
/// ```
/// FooEntity fe = await access.load(...);
/// ...
/// fe.insertFlavor = onConflictDoNothing;
/// ```
class SqlFlavorMixin implements SqlFlavor {
  @override
  String Function(String sql, Map? data)? insertFlavor;
  @override
  String Function(String sql, Map? data)? updateFlavor;
  @override
  String Function(String sql, Map? data)? deleteFlavor;
}

/// Flavor: on conflict do nothing
String onConflictDoNothing(String sql, Map? data)
=> "$sql on conflict do nothing";
