import 'dart:io';
import 'dart:async';
import 'package:xml/xml.dart' as xml;

class TestItem {
  String name;
  String description;
  String query;
  String input;
  TestItem(this.name, this.description, this.query,{this.input}){}
}

class Catalog {

  List<String> tests = [];
  Map<String,TestItem> testQueue = {};

  var contentRootPath = 'res/qt3_1_0/';

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

     var strXml = await new File('${contentRootPath}catalog.xml').readAsString();
     var doc = xml.parse(strXml);
     tests.forEach((t){
       doc.rootElement.children.where((x) => x is xml.XmlElement).forEach((xml.XmlElement e) async {
         if(t==e.getAttribute('name')) {
             var file = e.getAttribute('file');
             print(file);
             strXml = await new File('${contentRootPath}$file').readAsString();
             print('${contentRootPath}$file = $strXml');
             if(strXml!=null && strXml!='') {
               var testCaseDoc = xml.parse(strXml);
               testCaseDoc.rootElement.children
                   .where((x) =>
               x is xml.XmlElement && x.name.local == 'test-case')
                   .forEach((xml.XmlElement e) async {
                 var name = e.getAttribute('name');
                 xml.XmlElement query = getElementByName(e, 'test');
                 var strQuery;
                 if (query != null) {
                   strQuery = query.text;
                 }
                 xml.XmlElement description = getElementByName(e, 'description');
                 var strDescription;
                 if(description!=null){
                   strDescription = description.text;
                 }
                 xml.XmlElement env = getElementByName(e, 'environment');
                 if (env != null) { //get the source doc
                   var ref = env.getAttribute('ref');
                   var strEnv;
                   try {
                     strEnv = await new File(
                         '${contentRootPath}docs/${ref}.xml').readAsString();
                   }
                   catch (ex){
                     var envSource = env.findElements('source');
                     if(envSource!= null && envSource.length > 0){
                       try {
                         ref = envSource[0].getAttribute("file");
                         strEnv = await new File(
                             '${contentRootPath}prod/${ref}').readAsString();
                       }
                       catch (ex){
                         print('error reading environment file (2): $ex');
                       }
                     }
                     //strEnv = await new File(                         '${contentRootPath}/${ref}.xml').readAsString();
                   }
                   if (strEnv != null) {
                     this.testQueue[name] =
                     new TestItem(name, strDescription, strQuery, input: strEnv);
                   }
                   else {
                     this.testQueue[name] = new TestItem(name, strDescription, strQuery);
                   }
                 }
               });
             }
         }
       });
     });

     //var document = xml.parse(temp);
     return null;
   }

   xml.XmlElement getElementByName(xml.XmlElement parent, String name) {
     xml.XmlElement result = parent.children
         .firstWhere((y)=>y is xml.XmlElement && y.name.local == name,
         orElse:() => null);
     return result;

   }

}