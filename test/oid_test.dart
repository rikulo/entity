//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Thu, May 02, 2013  2:44:51 PM
// Author: tomyeh
library entity.oid_test;

import "dart:convert" show json;
import 'package:test/test.dart';
import 'package:entity/oid.dart';

void main() {
  test("OID Test", () {
    expect(isValidOid('_bcdefghijkl.nop-rs~uvwx'), true);
    expect(isValidOid('0bcdefghijklmn/pqrstuvwx'), false);
    expect(isValidOid('ABCDEFGHIJKLMNOPQRSTUVW;'), false);
    expect(isValidOid('ABCDEFGHIJKLMNOPQRSTUVW '), false);
    expect(isValidOid('ABCDEFGHIJKLMNOPQRST+UVW'), false);

    expect(isValidOid('_bcdefghijkl.nop-rs~'), false);
    expect(isValidOid('_bcdefghijkl.nop-rs~', ignoreLength: true), true);

    String? prevOid;
    String? prevTimePart;
    const loops = 100000;
    final t0 = DateTime.now(),
      oids = <String>{};
    for (int i = 0; i < loops; i++) {
      final oid = nextOid();
      expect(isValidOid(oid), true);
      expect(oids.add(oid), true); //not dup

      //make sure time part in alphabetica order
      final timePart = oid.substring(0, 5);
      if (prevTimePart != null)
        expect(timePart.compareTo(prevTimePart) >= 0, true,
            reason: 'pre=$prevOid vs oid=$oid');
      prevTimePart = timePart;

      expect(oid.indexOf('\\'), -1);
      expect(oid.indexOf('"'), -1);
      expect(json.encode(oid), '"$oid"'); //no escape
      expect(Uri.encodeComponent(oid), oid); //no escape
      expect(Uri.encodeQueryComponent(oid), oid); //no escape

      if (prevOid != null)
        expect(oid != prevOid, true);
      prevOid = oid;

      if (i < 20) print("$i: $oid");
    }
    print("Generate $loops OIDs in ${DateTime.now().difference(t0)}");
  });
}
