//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, May 06, 2013  3:08:02 PM
// Author: tomyeh
library entity.oid;

//Note: we use characters a-z, A-Z, 0-9 and _, s.t., the user  can select all
//by double-clicking it (they also valid characters no need of escapes).
//So, it is 26 * 2 + 10 + _ccExtra => 66 diff chars
//
//OID is 24 chars = 66^24 = 4.67e43
//so it is about 8.8e6 more than 128 bit UUID (where 122 is effective: 5.3e36)
//(note: Git revision is 36^40 about 1.79e62)

import "dart:math" show Random, pow;
import 'dart:typed_data';
import "package:charcode/ascii.dart";

/// The type of random generator.
///
/// * [length] specifies the number of integers to generate.
/// * Returned ints MUST be in the range [0, 2^32).
typedef List<int> GetRandomInts(int length);

/// Total number of characters per OID.
const oidLength = 24;

const _ccExtra = const <int> [
  $dash, $underline, $tilde, $dot
]; //( and ) => not valid in email
   //(, ), *, ! and , => encoded by encodeQueryComponent
//const _ccExtra2 = [$lparen, $rparen, $asterisk, $exclamation, ..._ccExtra];
  //(, ), *, !, => NOT encoded by JS encodeURIComponent 
  //69^24 = 1.35e44 => 2.9x => not worth

///The character range
const _ccRange = 66, //26*2+10+_ccExtra

  _intLen = 4, //# of integers: [_intLen] * [_charPerInt] + [_oidTimePart] >= [oidLength]
  _charPerInt = 5, //66^5 < 2^31 (66^5 / 2^31 = 0.5)
  _maxValuePerInt = _ccRange*_ccRange*_ccRange*_ccRange*_ccRange, //66 ^ [_charPerInt]

  _maxInt32 = 4294967296, //= 1 << 32 (note: in JS, we can't use 1 << 32 => 1)
  _threshold = _maxInt32 - (_maxInt32 % _maxValuePerInt),
    //To avoid modulo bias, use: value < _threshold
    //Modulo bias happens when you do `x % n` but x is uniform over a range
    //whose size isn't a multiple of n. Some remainders occur more often.
    //Thus, we need: _threshold % _maxValuePerInt == 0

  //Like UUIDv7, preserve a couple character for time-part
  //66^5 ms => 14.5 days => good enough for b-tree blocks
  _lenTimePart = 5,
  _maxTimePart = _ccRange*_ccRange*_ccRange*_ccRange*_ccRange, //66 ^ [_lenTimePart]
  _divTimePart = _maxTimePart ~/ _ccRange;

/// Returns the next unique object ID.
String nextOid() {
  final bytes = List<int>.filled(oidLength, 0);
  var out = 0;

  // ---- time part (MSB-first) ----
  var time = DateTime.now().millisecondsSinceEpoch % _maxTimePart;
  for (var i = _lenTimePart, div = _divTimePart; --i >= 0;) {
    final digit = time ~/ div;
    bytes[out++] = _escOid(digit);
    time %= div;
    div ~/= _ccRange;
  }

  // ---- random part ----
  for (;;) {
    var val = _safeRandom.next(); // uniform in [0, _threshold)
    assert(val >= 0);

    for (var j = _charPerInt; --j >= 0;) {
      bytes[out++] = _escOid(val % _ccRange);
      if (out >= oidLength)
        return String.fromCharCodes(bytes);
      val ~/= _ccRange;
    }
  }
}

/// Creates a new OID based two OIDs.
///
/// NOTE: requires oid1 and oid2 to be at least 12 chars long.
String mergeOid(String oid1, String oid2) {
  assert(isValidOid(oid1), oid1);
  assert(isValidOid(oid2), oid2);
  return "${oid1.substring(0, 12)}${oid2.substring(_lenTimePart, 12 + _lenTimePart)}";
}

/// Test if the given value is a valid OID.
///
/// Note: for performance reason, it does only the basic check.
///
/// - [ignoreLength] whether to check `value.length` is the same as [oidLength].
bool isValidOid(String value, {bool ignoreLength = false})
=> (ignoreLength || value.length == oidLength) && _reOid.hasMatch(value);

/// Regular expression pattern for matching single OID character.
const oidCharPattern = r'[-0-9a-zA-Z._~]';
/// Regular expression pattern for matching OID.
const oidPattern = '$oidCharPattern+';
final _reOid = RegExp('^$oidPattern\$');

/// The function used to generate a list of random integers to construct OID.
///
/// The default implementation uses [Random] to generate the random number.
/// When running at the browser, it is better to replace with
/// `Crypto.getRandomValues`.
GetRandomInts getRandomInts = _getRandomInts;

int _escOid(int v) => _charmap[v];
final _charmap = Uint8List.fromList([
  ...List.generate(10, (i) => $0 + i),
  ...List.generate(26, (i) => $A + i),
  ...List.generate(26, (i) => $a + i),
  ..._ccExtra
])..sort();

/// Used to retrieve the next integer without so-called modulo bias.
class _SafeRandom {
  late List<int> _values;
  var _i = 0;

  _SafeRandom() {
    assert(_charmap.length == _ccRange);
    assert(_threshold == 3756997728); //double check the calc
    assert(_threshold % _maxValuePerInt == 0);

    assert(_maxInt32 == pow(2, 32));
    assert(_maxValuePerInt < _maxInt32);
    assert(_ccRange == 26*2+10+_ccExtra.length);
    assert(_maxTimePart == pow(_ccRange, _lenTimePart));
    assert(_maxValuePerInt == pow(_ccRange, _charPerInt));
  }

  int next() {
    for (;;) {
      final val = _rawNext();
      if (val < _threshold) return val;
    }
  }

  int _rawNext() {
    if (_i <= 0)
      _values = getRandomInts(_i = _batchSize);
    return _values[--_i];
  }
}
final _safeRandom = _SafeRandom();
const _batchSize = _intLen * 2;

/// Default implementation of [getRandomInts].
List<int> _getRandomInts(int length) {
  final values = List<int>.filled(length, 0);
  for (var i = 0; i < length; i++) {
    values[i] = _random.nextInt(_maxInt32);
  }
  return values;
}

final _random = (() {
  try {
    final random = Random.secure();
    random.nextInt(2); //make sure it works
    return random;
  } catch (_) {
    return Random();
  }
})();
