//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Tue, Jul 01, 2014  3:36:38 PM
// Author: tomyeh
library entity.client_sample;

import "package:entity/entity.dart";

class Master extends Entity {
  String? name;

  Master(this.name);
  Master.be(String oid): super.be(oid);

  @override
  void write(AccessWriter writer, Map data, Set<String>? fields) {
    super.write(writer, data, fields);
    data["name"] = name;
  }
  @override
  void read(AccessReader reader, Map data, Set<String>? fields) {
    super.read(reader, data, fields);
    name = data["name"] as String?;
  }

  @override
  String get otype => "Master";
}

class Detail extends Entity {
  DateTime? createdAt;
  int? value;
  String? master;

  Detail(this.createdAt, this.value);
  Detail.be(String oid): super.be(oid);

  @override
  void write(AccessWriter writer, Map data, Set<String>? fields) {
    super.write(writer, data, fields);
    data["createdAt"] = createdAt;
    data["value"] = value;
    data["master"] = master;
  }
  @override
  void read(AccessReader reader, Map data, Set<String>? fields) {
    super.read(reader, data, fields);
    value = data["value"] as int?;
    createdAt = data["createdAt"] as DateTime?;
    master = data["master"] as String?;
  }

  @override
  String get otype => "Detail";
}

Master beMaster(String oid) => Master.be(oid);
Detail beDetail(String oid) => Detail.be(oid);
