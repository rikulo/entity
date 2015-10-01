//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, May 06, 2013  3:08:02 PM
// Author: tomyeh
library entity.oid;

import "dart:math" show Random, min;

//Note: we use characters a-z, A-Z, 0-9 and _, s.t., the user  can select all
//by double-clicking it (they also valid characters no need of escapes).
//So, it is 26 * 2 + 10 + 1 => 63 diff chars
//
//OID is 24 chars (23 random number + 1 random sequential number) > 63^23 = 2.4e41
//so it is about 10K more than 128 bit UUID (where 122 is effective: 5.3e36)
//(note: Git revision is 2^40 about 1.46e48)

/** The type of random generator
 *
 * * [length] specifies the number of integers to generate.
 */
typedef List<int> GetRandomInts(int length);

///Total number of characters per OID.
const int OID_LENGTH = 24; //first char is sequential and the rest is random

///The character range
const int _CC_RANGE = 63, _CC_0 = 48, _CC_9 = _CC_0 + 9, _CC_A = 65, _CC_a = 97,
  _CC_UNDERSCORE = 95; //_
const int
  _INT_LEN = 5, //# of integers: _INT_LEN * _CHAR_PER_INT >= OID_LENGTH - 1 + 2
  _CHAR_PER_INT = 5; //63^5 < 2^31 (63^5: 992,436,543, 2^31: 2,147,483,648)

/** Returns the next unique object ID.
 *
 * * [seed] - whether to re-generate a new seed. It is useful if
 *  you'd like to generate a secure link (s.t., the user is hard to guess
 * what will be next). The side effect is a little performance overhead.
 */
String nextOid({bool seed:false}) {
  if (seed || ++_prefix > _prefixEnd)
    seedOid();
  return new String.fromCharCode(_escOid(_prefix)) + _body;
}
/** Creates a new OID based two OIDs.
 *
 * > To shorten the result OID, we retrieve the substring of [oid1] and [oid2]
 * and concatenate them together. Of course, there might be conflict but
 * the chance is so low that we can ignore (like OID generator),
 */
String mergeOid(String oid1, String oid2)
=> "${oid1.substring(0, 12)}${oid2.substring(0, 12)}";

/** Changes the seed of OID, such that next invocation of [nextOid]
 * will return a totally different sequence.
 */
void seedOid() {
  final values = getRandomInts(_INT_LEN);
  assert(values.length == _INT_LEN);
  final List<int> bytes = [];
  for (int i = values.length; --i >= 0;) {
    int val = values[i];
    if (val < 0)
      val = -val;

    for (int j = _CHAR_PER_INT;;) {
      bytes.add(val % _CC_RANGE);

      if (--j == 0)
        break;
      val = val ~/ _CC_RANGE;
    }
  }

  _prefix = bytes[OID_LENGTH - 1] & 0x1f;
  _prefixEnd = min((bytes[OID_LENGTH] & 0x1f) + _prefix + 5,
      _CC_RANGE - 1);

  bytes.removeRange(OID_LENGTH - 1, _CHAR_PER_INT * _INT_LEN);
  for (int i = OID_LENGTH - 1; --i >= 0;)
    bytes[i] = _escOid(bytes[i]);
  _body = new String.fromCharCodes(bytes);
}

///Test if the given value is a valid OID.
///
///Note: for performance reason, it does only the basic check.
bool isValidOid(String value)
=> value.length == OID_LENGTH && _oidPattern.firstMatch(value) != null;

final RegExp _oidPattern = new RegExp(r'^[0-9a-zA-Z_]*$');

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
  return _CC_UNDERSCORE;
}

final Random _random = new Random();
String _body;
int _prefix = 0, _prefixEnd = 0;
    //force _nextOid2 to call seedOid first
