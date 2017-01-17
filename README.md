# XML Query Test Driver

Driver for offical XML Query test suite (https://dev.w3.org/2011/QT3-test-suite/). Includes full catalog.

## Usage

A simple usage example:

    import 'package:xml_query_test_driver/xml_query_test_driver.dart';

    main() {
      var catalog = new Catalog('my-path-to-selected-tests.xml');
    }
    
my-path-to-selected-tests.xml (eg):

    <tests>
        <set>prod-AxisStep</set>
        <set>prod-AxisStep.ancestor</set>
        <set>prod-AxisStep.following</set>
    </tests>

## Features and bugs

Please file feature requests and bugs at TBA.

