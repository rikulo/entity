//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Mon, Jun 30, 2014  4:00:13 PM
// Author: tomyeh
library entity.map_store_test;

import "dart:async";
import 'package:unittest/unittest.dart';
import 'package:entity/entity.dart';
import 'package:entity/map_storage.dart';

import "client_sample.dart";

final MapStorageAccess access = new MapStorageAccess();

void main() {
  Master m1 = new Master("m1");
  Detail d1 = new Detail(new DateTime.now(), 100);
  Detail d2 = new Detail(new DateTime.now(), 200);
  m1.details..add(d1)..add(d2);
  d1.save(access);
  d2.save(access);
  m1.save(access);
  access.clearCache();

  test("Entity Test on Map",
    //Note: we have to load details first, since Master.read() invokies
    //reader.entities().
    () => Future.wait([
        load(access, d1.oid, beDetail),
        load(access, d2.oid, beDetail)])
    .then((_) => load(access, m1.oid, beMaster))
    .then((Master m) {
      expect(identical(m, m1), false); //not the same instance
      expect(m.name, m1.name);
      expect(m.details.length, m1.details.length);

      for (int i = m.details.length; --i >= 0;) {
        expect(m.details[i].when, m1.details[i].when);
        expect(m.details[i].value, m1.details[i].value);
      }
    })
  );
}
