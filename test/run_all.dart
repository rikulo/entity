//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Tue, Apr 09, 2013  4:50:32 PM
// Author: tomyeh
library test_run_all;

import 'package:unittest/unittest.dart';

import 'oid_test.dart' as oid_test;

main() {
  group("oid tests", oid_test.main);
}
