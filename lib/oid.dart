//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, May 06, 2013  3:08:02 PM
// Author: tomyeh
library entity.oid;

import "dart:math" show Random;

//Note: we use characters a-z, A-Z, 0-9 and _, s.t., the user  can select all
//by double-clicking it (they also valid characters no need of escapes).
//So, it is 26 * 2 + 10 + 1 => 68 diff chars
//
//OID is 24 chars = 68^24 = 9.5e43
//so it is about 2.8e6 more than 128 bit UUID (where 122 is effective: 5.3e36)
//(note: Git revision is 36^40 about 1.79e62)

/** The type of random generator
 *
 * * [length] specifies the number of integers to generate.
 */
typedef List<int> GetRandomInts(int length);

///Total number of characters per OID.
const int OID_LENGTH = 24;

const List<int> _CC_EXTRA = const <int> [
  33/*!*/, 42/***/, 45/*-*/, 46/*.*/, 95/*_*/, 126/*~*/,
]; //40/*(*/, 41/*)*/ => not valid in email

///The character range
const int _CC_RANGE = 68, //26*2+10+_CC_EXTRA.length
  _CC_0 = 48, _CC_9 = _CC_0 + 9, _CC_A = 65, _CC_a = 97; //_
const int
  _INT_LEN = 5, //# of integers: _INT_LEN * _CHAR_PER_INT >= OID_LENGTH - 1 + 2
  _CHAR_PER_INT = 5; //68^5 < 2^31 (68^5: 1,453,933,568, 2^31: 2,147,483,648)

/** Returns the next unique object ID.
 */
String nextOid() {
  final values = getRandomInts(_INT_LEN);
  assert(values.length == _INT_LEN);
  final List<int> bytes = [];
  l_gen:
  for (int i = values.length; --i >= 0;) {
    int val = values[i];
    if (val < 0)
      val = -val;

    for (int j = _CHAR_PER_INT;;) {
      bytes.add(_escOid(val % _CC_RANGE));
      if (bytes.length >= OID_LENGTH)
        break l_gen;

      if (--j == 0)
        break;
      val = val ~/ _CC_RANGE;
    }
  }

  return new String.fromCharCodes(bytes);
}
/** Creates a new OID based two OIDs.
 *
 * > To shorten the result OID, we retrieve the substring of [oid1] and [oid2]
 * and concatenate them together. Of course, there might be conflict but
 * the chance is so low that we can ignore (like OID generator),
 */
String mergeOid(String oid1, String oid2)
=> "${oid1.substring(0, 12)}${oid2.substring(0, 12)}";

///Test if the given value is a valid OID.
///
///Note: for performance reason, it does only the basic check.
bool isValidOid(String value)
=> value.length == OID_LENGTH && _oidPattern.firstMatch(value) != null;

final RegExp _oidPattern = new RegExp(r'^[-0-9a-zA-Z!*._~]*$');

/** The function used to generate a list of random integers to construct OID.
 *
 * The default implementation uses [Random] to generate the random number.
 * When running at the browser, it is better to replace with
 * `Crypto.getRandomValues`.
 */
 GetRandomInts getRandomInts = _getRandomInts;

///Default implementation of [getRandomInts]
List<int> _getRandomInts(int length) {
  final values = new List<int>(length);
  for (int i = length; --i >= 0;) {
    values[i] = (_random.nextDouble() * 0xffffffff).toInt();
      //we can't use (1 << 32) -1, which causes an exception if dart2js

    //make it more random since some browser doesn't generate random well
    if (i == 2)
      values[i] += new DateTime.now().millisecondsSinceEpoch;
  }
  return values;
}

int _escOid(int v) {
  if (v < 10)
    return _CC_0 +  v;
  if ((v -= 10) < 26)
    return _CC_A + v;
  if ((v -= 26) < 26)
    return _CC_a + v;
  return _CC_EXTRA[v - 26];
}

final Random _random = new Random();
