//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Tue, Jul 01, 2014 10:02:56 AM
// Author: tomyeh
library entity.nosql_sample;

import "package:entity/entity.dart";

class Master extends Entity {
  String name;
  ///A list of OID of [Detail] instances.
  List<String> details;

  Master(this.name): details = [];
  Master.be(String oid): super.be(oid);

  @override
  void write(AccessWriter writer, Map data, Set<String> fields) {
    super.write(writer, data, fields);
    data["name"] = name;
    data["details"] = details;
  }
  @override
  void read(AccessReader reader, Map data, Set<String> fields) {
    super.read(reader, data, fields);
    name = data["name"] as String;
    details = (data["details"] as List).cast<String>();
  }

  @override
  String get otype => "Master";
}

class Detail extends Entity {
  DateTime createdAt;
  int value;

  Detail(this.createdAt, this.value);
  Detail.be(String oid): super.be(oid);

  @override
  void write(AccessWriter writer, Map data, Set<String> fields) {
    super.write(writer, data, fields);
    data["createdAt"] = writer.dateTime(createdAt);
    data["value"] = value;
  }
  @override
  void read(AccessReader reader, Map data, Set<String> fields) {
    super.read(reader, data, fields);
    value = data["value"] as int;
    createdAt = reader.dateTime(data["createdAt"]);
  }

  @override
  String get otype => "Detail";
}

Master beMaster(String oid) => Master.be(oid);
Detail beDetail(String oid) => Detail.be(oid);
