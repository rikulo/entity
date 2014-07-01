//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Tue, Jul 01, 2014 10:02:56 AM
// Author: tomyeh
library entity.client_sample;

import "dart:async";
import 'package:entity/entity.dart';

class Master extends Entity {
  String name;
  ///A list of OID of [Detail] instances.
  List<String> details;

  Master(this.name): details = [];
  Master.be(String oid): super.be(oid);

  @override
  void write(AccessWriter writer, Map<String, dynamic> data, Set<String> fields) {
    super.write(writer, data, fields);
    data["name"] = name;
    data["details"] = details;
  }
  @override
  void read(AccessReader reader, Map<String, dynamic> data, Set<String> fields) {
    super.read(reader, data, fields);
    name = data["name"];
    details = data["details"];
  }

  @override
  String get otype => "Master";
}

class Detail extends Entity {
  DateTime when;
  int value;

  Detail(this.when, this.value);
  Detail.be(String oid): super.be(oid);

  @override
  void write(AccessWriter writer, Map<String, dynamic> data, Set<String> fields) {
    super.write(writer, data, fields);
    data["when"] = writer.dateTime(when);
    data["value"] = value;
  }
  @override
  void read(AccessReader reader, Map<String, dynamic> data, Set<String> fields) {
    super.read(reader, data, fields);
    value = data["value"];
    when = reader.dateTime(data["when"]);
  }

  @override
  String get otype => "Detail";
}

Master beMaster(String oid) => new Master.be(oid);
Detail beDetail(String oid) => new Detail.be(oid);
