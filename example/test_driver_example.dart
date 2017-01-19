// Copyright (c) 2017, Peter. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'package:xml_query_test_driver/xml_query_test_driver.dart';

main() {
  var awesome = new Catalog();
  awesome.setup("asdf");
  awesome.buildTestCases().then((Catalog cat){
    cat.testQueue.values.forEach((t)=>print('Test= ${t.name} ${t.query}'));
  });
}
