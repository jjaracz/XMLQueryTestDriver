import 'dart:io';
import 'dart:async';
import 'package:xml/xml.dart' as xml;

class Catalog {

  List<String> tests = [];

  ///xml list of required tests in the form of
  ///<tests><set>[set name]</set>...</tests>
   void setup(path){
     var temp = '''<tests>
                      <set>prod-AxisStep</set>
                      <set>prod-AxisStep.ancestor</set>
                      <set>prod-AxisStep.following</set>
                   </tests>''';
     var doc = xml.parse(temp);
     doc.rootElement.children.where((x) => x is xml.XmlElement).forEach((xml.XmlElement e){
       tests.add(e.text);
     });

     //for each test line
     //1. get the line in the catalog
     //2. get the source file
     tests.forEach((s)=>print(s));

   }

   Future printTestCases() async {
     var contentRootPath = 'res/qt3_1_0/';
     var contents = await new File('${contentRootPath}catalog.xml').readAsString();
     print(contents);
     //var document = xml.parse(temp);
     return null;
   }

}