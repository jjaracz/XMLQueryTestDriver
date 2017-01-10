import 'dart:io';
import 'dart:async';
import 'package:xml/xml.dart' as xml;

class Catalog {

   Future printTestCases() async {
     var contents = await new File('res/qt3_1_0/catalog.xml').readAsString();
     print(contents);
     //var document = xml.parse(temp);
     return null;
   }

}