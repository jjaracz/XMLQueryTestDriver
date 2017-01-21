# XML Query Test Driver

Driver for official XML Query test suite (https://dev.w3.org/2011/QT3-test-suite/). Includes full catalog.

## Usage

Include this package locally to the implementation project.

A simple usage example:

    import 'package:xml_query_test_driver/xml_query_test_driver.dart';

    main() async {
      var testDriver = new TestDriver();
      testDriver.setup('[your_test_sets].xml');
      await testDriver.buildTestCases();
      testDriver.testQueue.forEach((k,v)=> print(testDriver.executeTest(v,doXPath)));
    }

    //test stub only replace reference to this method with the implementation eval call
    String doXPath(String xpath, String src){
      return '$xpath $src';
    }
    
my-path-to-selected-tests.xml (eg):

    <tests>
        <set>prod-AxisStep</set>
        <set>prod-AxisStep.ancestor</set>
        <set>prod-AxisStep.following</set>
    </tests>

## Features and bugs

Please file feature requests and bugs at TBA.

