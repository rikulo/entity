//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Thu, May 02, 2013  2:44:51 PM
// Author: tomyeh
library entity.oid_test;

import "dart:html";
import "dart:convert" show JSON;
import "dart:typed_data";

import 'package:test/test.dart';
import 'package:entity/oid.dart';

void main() {
  getRandomInts =  _getCryptoInts;

  test("OID Dump Test", () {
    expect(isValidOid('_bcdefghijkl.nop-rstuvwx'), isTrue);
    expect(isValidOid('0bcdefghijklmn/pqrstuvwx'), isFalse);
    expect(isValidOid('ABCDEFGHIJKLMNOPQRSTUVW;'), isFalse);
    expect(isValidOid('ABCDEFGHIJKLMNOPQRSTUVW '), isFalse);
    expect(isValidOid('ABCDEFGHIJKLMNOPQRST+UVW'), isFalse);

    String prevOid;
    const int LOOPS = 100000;
    final DateTime t0 = new DateTime.now();
    for (int i = 0; i < LOOPS; i++) {
      final String oid = nextOid();
      expect(isValidOid(oid), isTrue);
      expect(oid.indexOf('\\'), -1);
      expect(oid.indexOf('"'), -1);
      expect(JSON.encode(oid), '"$oid"'); //no escape
      expect(Uri.encodeComponent(oid), oid); //no escape

      if (prevOid != null)
        expect(oid != prevOid, isTrue);
      prevOid = oid;

//      if (i < 500)
//        _print("$i: $oid");
    }
    _print("Generate $LOOPS OIDs in ${new DateTime.now().difference(t0)}");
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

List<int> _getCryptoInts(int length) {
  final values = new Uint32List(length);
  window.crypto.getRandomValues(values);
  return values;
}
