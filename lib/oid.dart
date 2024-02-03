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
  $dash, $underline, $tilde, $dot //NOTE: $dot must NOT be the last; see below
]; //( and ) => not valid in email
   //(, ), *, ! and , => encoded by encodeQueryComponent
//const _ccExtra2 = [$lparen, $rparen, $asterisk, $exclamation, ..._ccExtra];
  //(, ), *, !, => NOT encoded by JS encodeURIComponent 
  //69^24 = 1.35e44 => 2.9x => not worth

///The character range
const int _ccRange = 66; //26*2+10+_CC_EXTRA
const int
  _intLen = 5, //# of integers: [_intLen] * [_charPerInt] >= [oidLength]
  _charPerInt = 5; //65^5 < 2^32 (65^5: 1,160,290,625, 2^32: 4,294,967,296)

/// Returns the next unique object ID.
String nextOid() {
  final bytes = <int>[],
    values = getRandomInts(_intLen);
  assert(values.length == _intLen);
  var remainding = 0;

  l_gen:
  for (int i = values.length, bl = 0; --i >= 0;) {
    int val = values[i];
    if (val < 0)
      val = -val;

    for (int j = _charPerInt;;) {
      bytes.add(_escOid(val % _ccRange));
      if (++bl >= oidLength) break l_gen;

      val = val ~/ _ccRange;
      if (--j == 0) {
        remainding = (remainding << 2) + val;
        break;
      }
    }
  }

  // We don't end OID with [$dot] (for easy parsing in, say, markdown)
  if (bytes.last == $dot) {
    assert(_ccExtra.last == $dot); //we assumet it so we mod `_ccRange - 1` below
    bytes.last = _escOid(remainding % (_ccRange - 1));
  }

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

/// Test if the given value is a valid OID.
///
/// Note: for performance reason, it does only the basic check.
///
/// - [ignoreLength] whether to check `value.length` is the same as
/// [oidLength].
bool isValidOid(String value, {bool ignoreLength = false})
=> (ignoreLength || value.length == oidLength) && _reOid.hasMatch(value);

/// Regular expression pattern for matching single OID character.
const oidCharPattern = r'[-0-9a-zA-Z._~]';
/// Regular expression pattern for matching OID.
const oidPattern = '$oidCharPatter+';
final _reOid = RegExp('^$oidPattern\$');

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
    values.add(_nextRandom(_maxRandom));
  return values;
}
const _maxRandom = 4294967296; //note: we can't use 1 << 32 (in JS, it will be 1)

int _escOid(int v) {
  if (v < 10)
    return $0 +  v;
  if ((v -= 10) < 26)
    return $A + v;
  if ((v -= 26) < 26)
    return $a + v;
  return _ccExtra[v - 26];
}

int _nextRandom(int max) {
  try {
    return _secureRandom.nextInt(max);
  } catch (_) { //possible if running out of file descriptors
    return _simpleRandom.nextInt(max);
  }
}

final _secureRandom = (() {
  try {
    return Random.secure();
  } catch (_) {
    return _simpleRandom;
  }
})();
final _simpleRandom = Random();
