//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Thu, May 02, 2013  2:44:51 PM
// Author: tomyeh
library entity.oid_test;

import "dart:convert" show JSON;
import 'package:unittest/unittest.dart';
import 'package:entity/oid.dart';

void main() {
  test("OID Test", () {
    expect(isValidOid('abcdefghijklmnopqrstuvwx'), isFalse);
    expect(isValidOid('abcdefghijklmnopqrstuvwX'), isTrue);
    expect(isValidOid('_bcdefghijklmnopqrstuvwx'), isFalse);
    expect(isValidOid('0bcdefghijklmnopqrstuvwx'), isTrue);
    expect(isValidOid('ABCDEFGHIJKLMNOPQRSTUVWX'), isFalse);
    expect(isValidOid('ABCDEFGHIJKLMNOPQRSTUVwX'), isTrue);
    expect(isValidOid('A_CDEFGHIJKLMNOPQRSTUVWX'), isFalse);
    expect(isValidOid('012345678901234567890123'), isTrue);

    String prevOid;
    const int LOOPS = 15000;
    int cntSeed = 0;
    for (int i = 0, cntOid = 0; i < LOOPS; i++) {
      final String oid = nextOid();
      expect(isValidOid(oid), isTrue);
      expect(oid.indexOf('\\'), -1);
      expect(oid.indexOf('"'), -1);
      expect(JSON.encode(oid), '"$oid"'); //no escape
      expect(Uri.encodeComponent(oid), oid); //no escape

      ++cntOid;
      if (prevOid != null) {
        expect(oid != prevOid, isTrue);

        if (oid.substring(1) != prevOid.substring(1)) {
          ++cntSeed;
          logMessage("$cntSeed: $prevOid => $oid (#$cntOid)");
          cntOid = 0;
        }
      }
      prevOid = oid;

//      if (i < 500)
//        logMessage("$i: $oid");
    }
    logMessage("Average: ${LOOPS / cntSeed} per seed");
  });
}
