// Copyright (c) 2017, Peter. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'package:xml_query_test_driver/xml_query_test_driver.dart';

main() async {
  var awesome = new Catalog();
  awesome.setup('asdf');
  await awesome.buildTestCases();
  print('in main call back:${awesome.testQueue.length}');
  awesome.testQueue.values.forEach((t)=>print('Test= ${t.name} ${t.query}'));

}
