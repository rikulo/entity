//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Thu, May 02, 2013  2:44:51 PM
// Author: tomyeh
library entity.oid_test;

import "dart:convert" show json;
import 'package:test/test.dart';
import 'package:entity/oid.dart';

void main() {
  test("OID Test", () {
    expect(isValidOid('_bcdefghijkl.nop-rstuvwx'), isTrue);
    expect(isValidOid('0bcdefghijklmn/pqrstuvwx'), isFalse);
    expect(isValidOid('ABCDEFGHIJKLMNOPQRSTUVW;'), isFalse);
    expect(isValidOid('ABCDEFGHIJKLMNOPQRSTUVW '), isFalse);
    expect(isValidOid('ABCDEFGHIJKLMNOPQRST+UVW'), isFalse);

    String prevOid;
    const int loops = 100000;
    final DateTime t0 = DateTime.now();
    for (int i = 0; i < loops; i++) {
      final String oid = nextOid();
      expect(isValidOid(oid), isTrue);
      expect(oid[oid.length - 1] == '.', isFalse); //don't end with dot
      expect(oid.contains('..'), isFalse);

      expect(oid.indexOf('\\'), -1);
      expect(oid.indexOf('"'), -1);
      expect(json.encode(oid), '"$oid"'); //no escape
      expect(Uri.encodeComponent(oid), oid); //no escape
      expect(Uri.encodeQueryComponent(oid), oid); //no escape

      if (prevOid != null)
        expect(oid != prevOid, isTrue);
      prevOid = oid;

//      if (i < 500)
//        print("$i: $oid");
    }
    print("Generate $loops OIDs in ${DateTime.now().difference(t0)}");
  });
}
