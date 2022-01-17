//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, May 03, 2013  5:54:12 PM
// Author: tomyeh
library entity;

import "dart:async";
import "dart:collection";

import "package:rikulo_commons/util.dart";

import "oid.dart";

part "src/entity/entity_core.dart";
part "src/entity/entity_access.dart";
part "src/entity/entity_helper.dart";

///The field name for storing `otype`.
const String fdOtype = "otype";
///The field name for soring `oid`.
const String fdOid = "oid";
