// Copyright (c) 2017, Peter. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
import 'package:xml_query_test_driver/xml_query_test_driver.dart';

main() async {
  var testDriver = new TestDriver();
  testDriver.setup('example/testlist.xml');
  await testDriver.buildTestCases();
  print('in main call back:${testDriver.testQueue.length}');
  testDriver.testQueue.forEach((k,v)=> print(testDriver.executeTest(v,doXPath)));

}

///test stub only replace this call with the implementation eval call
String doXPath(String xpath, String src){
  return '$xpath $src';
}