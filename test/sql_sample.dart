//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Tue, Jul 01, 2014  3:36:38 PM
// Author: tomyeh
library entity.client_sample;

import 'package:entity/entity.dart';

class Master extends Entity {
  String name;

  Master(this.name);
  Master.be(String oid): super.be(oid);

  @override
  void write(AccessWriter writer, Map<String, dynamic> data, Set<String> fields) {
    super.write(writer, data, fields);
    data["name"] = name;
  }
  @override
  void read(AccessReader reader, Map<String, dynamic> data, Set<String> fields) {
    super.read(reader, data, fields);
    name = data["name"];
  }

  @override
  String get otype => "Master";
}

class Detail extends Entity {
  DateTime createdAt;
  int value;
  String master;

  Detail(this.createdAt, this.value);
  Detail.be(String oid): super.be(oid);

  @override
  void write(AccessWriter writer, Map<String, dynamic> data, Set<String> fields) {
    super.write(writer, data, fields);
    data["createdAt"] = createdAt;
    data["value"] = value;
    data["master"] = master;
  }
  @override
  void read(AccessReader reader, Map<String, dynamic> data, Set<String> fields) {
    super.read(reader, data, fields);
    value = data["value"];
    createdAt = data["createdAt"];
    master = data["master"];
  }

  @override
  String get otype => "Detail";
}

Master beMaster(String oid) => new Master.be(oid);
Detail beDetail(String oid) => new Detail.be(oid);
