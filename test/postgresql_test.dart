//Copyright (C) 2014 Potix Corporation. All Rights Reserved.
//History: Tue, Jul 01, 2014 12:58:00 PM
// Author: tomyeh

import "dart:async";

import 'package:test/test.dart';
import "package:entity/entity.dart";
import "package:entity/postgresql2.dart";

import "package:postgresql2/postgresql.dart" show Connection, connect;

import "sql_sample.dart";

const String dbUri = "postgres://postgres:123@localhost:5432/testdb";

void main() {
  test("Entity Test on PostgreSQL", test1);
}

Future test1() async {
  Connection? conn;
  try {
    conn = await connect(dbUri);
    await initDB(conn);
    final access = PostgresqlAccess(conn, cache: false);
    Master m1 = Master("m1");
    Detail d1 = Detail(DateTime.now(), 100);
    d1.master = m1.oid;
    Detail d2 = Detail(DateTime.now(), 200);
    d2.master = m1.oid;

    await Future.forEach([m1, d1, d2], (Entity e) => e.save(access, null));

    final m = await load(access, m1.oid, beMaster);
    expect(m, m1);
    expect(identical(m, m1), isFalse); //not the same instance
    expect(m.name, m1.name);

    final d = await load(access, d1.oid, beDetail, const ["value", "createdAt"]);
    expect(identical(d, d1), isFalse);
  //      expect(d.createdAt, d1.createdAt);
    expect(d.value, d1.value);
    expect(d.master, isNull);

  } finally {
    if (conn != null) {
      conn.close();
    } else {
      print("Make sure you create a case-sensitive database called testdb");
    }
  }
}

Future initDB(Connection conn)
=> Future.forEach(const [
  """
  create temporary table "Master" (
    "oid" varchar(40) primary key,
    "name" varchar(60),
    "foo" json null
  )
  """, """
  create temporary table "Detail" (
    "oid" varchar(40) primary key,
    "createdAt" timestamptz null,
    "value" integer,
    "master" varchar(40) null references "Master"("oid")
  )
  """],
  (String stmt) => conn.execute(stmt));
