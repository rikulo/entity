//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, May 06, 2013  3:08:02 PM
// Author: tomyeh
library entity.oid;

import "dart:math" show Random;
import "package:charcode/ascii.dart";

//Note: we use characters a-z, A-Z, 0-9 and _, s.t., the user  can select all
//by double-clicking it (they also valid characters no need of escapes).
//So, it is 26 * 2 + 10 + _CC_EXTRA => 65 diff chars
//
//OID is 24 chars = 65^24 = 3.2e43
//so it is about 2.8e6 more than 128 bit UUID (where 122 is effective: 5.3e36)
//(note: Git revision is 36^40 about 1.79e62)

/** The type of random generator
 *
 * * [length] specifies the number of integers to generate.
 */
typedef List<int> GetRandomInts(int length);

///Total number of characters per OID.
const int oidLength = 24;

const _ccExtra = const <int> [
  $dash, $underline, $dot, $tilde
]; //( and ) => not valid in email
   //* and , => not safe
   //! and , => it will be encoded by encodeQueryComponent

///The character range
const int _ccRange = 66; //26*2+10+_CC_EXTRA
const int
  _intLen = 5, //# of integers: _INT_LEN * _CHAR_PER_INT >= OID_LENGTH - 1 + 2
  _charPerInt = 5; //65^5 < 2^31 (65^5: 1,160,290,625, 2^31: 2,147,483,648)

/** Returns the next unique object ID.
 */
String nextOid() {
  final values = getRandomInts(_intLen);
  assert(values.length == _intLen);
  final List<int> bytes = [];
  l_gen:
  for (int i = values.length; --i >= 0;) {
    int val = values[i];
    if (val < 0)
      val = -val;

    for (int j = _charPerInt;;) {
      bytes.add(_escOid(val % _ccRange));
      if (bytes.length >= oidLength)
        break l_gen;

      if (--j == 0)
        break;
      val = val ~/ _ccRange;
    }
  }

  //The last characters shall not be a dot. Otherwise, it is easy to get
  //confused if we put URL at the end of a sentence.
  final last = bytes.length - 1;
  if (bytes[last] == $dot) bytes[last] = $z;

  return String.fromCharCodes(bytes);
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
=> value.length == oidLength && _oidPattern.hasMatch(value);

final _oidPattern = RegExp(r'^[-0-9a-zA-Z._~]*$');

/** The function used to generate a list of random integers to construct OID.
 *
 * The default implementation uses [Random] to generate the random number.
 * When running at the browser, it is better to replace with
 * `Crypto.getRandomValues`.
 */
 GetRandomInts getRandomInts = _getRandomInts;

///Default implementation of [getRandomInts]
List<int> _getRandomInts(int length) {
  final values = <int>[];
  while (--length >= 0)
    values.add(_random.nextInt(1<<31));
  return values;
}

int _escOid(int v) {
  if (v < 10)
    return $0 +  v;
  if ((v -= 10) < 26)
    return $A + v;
  if ((v -= 26) < 26)
    return $a + v;
  return _ccExtra[v - 26];
}

final _random = Random();
