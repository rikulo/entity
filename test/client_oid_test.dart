//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Thu, May 02, 2013  2:44:51 PM
// Author: tomyeh
library entity_oid_test;

import "dart:html";
import "dart:convert" show JSON;
import 'package:unittest/unittest.dart';
import 'package:entity/oid.dart';

void main() {
  test("OID Dump Test", () {
    String prevOid;
    const int LOOPS = 15000;
    int cntSeed = 0;
    for (int i = 0, cntOid = 0; i < LOOPS; i++) {
      final oid = nextOid();
      expect(oid.length, OID_LENGTH);
      expect(oid.indexOf('\\'), -1);
      expect(oid.indexOf('"'), -1);
      expect(JSON.encode(oid).length, OID_LENGTH + 2);

      ++cntOid;
      if (prevOid != null) {
        expect(oid != prevOid, isTrue);

        if (oid.substring(1) != prevOid.substring(1)) {
          ++cntSeed;
          _print("$cntSeed: $prevOid => $oid (#$cntOid)");
          cntOid = 0;
        }
      }
      prevOid = oid;

//      if (i < 500)
//        _print("$i: $oid");
    }
    _print("Average: ${LOOPS / cntSeed} per seed");
  });
}

void _print(String message) {
  if (_out == null) {
    _out = document.querySelector("#dump");
    _out.value = "";
  }
  _out.value = _out.value + message + '\n';
}
TextAreaElement _out;