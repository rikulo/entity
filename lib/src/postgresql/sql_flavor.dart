//Copyright (C) 2020 Potix Corporation. All Rights Reserved.
//History: Wed Feb 26 10:41:23 CST 2020
// Author: tomyeh
part of entity.postgresql;

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
  String Function(String sql, Map data) get insertFlavor;
  /// A callback to return the adjusted SQL UPDATE statement ([sql]).
  String Function(String sql, Map data) get updateFlavor;
}

/// Used to simplify the implementation of [SqlFlavor].
class SqlFlavorMixin implements SqlFlavor {
  @override
  String Function(String sql, Map data) insertFlavor;
  @override
  String Function(String sql, Map data) updateFlavor;
}

/// Flavor: on conflict do nothing
String onConflictDoNothing(String sql, Map data)
=> "$sql on conflict do nothing";
