//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Mon, Jun 30, 2014  4:00:13 PM
// Author: tomyeh
library entity.couchbse_test;

import "dart:async";

import 'package:unittest/unittest.dart';
import 'package:entity/entity.dart';
import 'package:entity/couchbase.dart';

import "package:couchclient/couchclient.dart"
  show CouchClient;

import "server_sample.dart";

CouchbaseAccess access;

void main() {
  test("Entity Test on Couchbase", test1);
}

Future test1() {
  final List<Uri> baseList = [Uri.parse("http://127.0.0.1:8091/pools")];
  return CouchClient.connect(baseList, "default", null)
  .then((CouchClient client) {
    access = new CouchbaseAccess(client);

    Master m1 = new Master("m1");
    Detail d1 = new Detail(new DateTime.now(), 100);
    Detail d2 = new Detail(new DateTime.now(), 200);
    m1.details..add(d1.oid)..add(d2.oid);

    return Future.wait([d1.save(access), d2.save(access), m1.save(access)])
    .then((_) => load(access, m1.oid, beMaster))
    .then((Master m) {
      expect(identical(m, m1), false); //not the same instance
      expect(m.name, m1.name);
      expect(m.details.length, m1.details.length);

      for (int i = m.details.length; --i >= 0;)
        expect(m.details[i], m1.details[i]);

      return Future.wait([m1.delete(access), d1.delete(access), d2.delete(access)]);
    })
    .then((_) => loadIfAny(access, m1.oid, beMaster))
    .then((Master m) {
      expect(m, isNull);

      access.client.close();
    });
  });
}
