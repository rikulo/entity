//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Mon, Jun 30, 2014  5:51:34 PM
// Author: tomyeh
library entity.postgresql2;

import "dart:async";
import "dart:collection" show HashMap;

import "package:postgresql2/postgresql.dart" show Connection, Row;
import "package:rikulo_commons/util.dart";

import "entity.dart";

part "src/postgresql/postgresql.dart";
part "src/postgresql/sql_flavor.dart";
