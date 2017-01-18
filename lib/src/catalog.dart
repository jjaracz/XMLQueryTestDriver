import 'dart:io';
import 'dart:async';
import 'package:xml/xml.dart' as xml;

enum ResultType {
  ERROR,
  ASSERT_XML,
  ASSERT_STRING,
  ASSERT_EQ,
  ASSERT_TRUE,
  ASSERT_FALSE,
  ASSERT_EMPTY,
  ASSERT_COUNT
}

class ResultItem {
  ResultType type;
  String value;
  ResultItem(this.type, this.value);
}

class TestItem {
  String name;
  String description;
  String author;
  String query;
  String input;
  List<ResultItem> result = [];
  TestItem(this.name, this.description, this.query,{this.input,this.author}){}
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
       var name;
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
                 name = e.getAttribute('name');

                 //test
                 xml.XmlElement query = getElementByName(e, 'test');
                 var strQuery;
                 if (query != null) {
                   strQuery = query.text;
                 }

                 //author
                 xml.XmlElement author = getElementByName(e, 'created');
                 var strAuthor;
                 if(author!=null){
                   strAuthor = author.getAttribute('by');
                 }

                 //description
                 xml.XmlElement description = getElementByName(e, 'description');
                 var strDescription;
                 if(description!=null){
                   strDescription = description.text;
                 }

                 //environment
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
                   }
                   if (strEnv != null) {
                     this.testQueue[name] =
                     new TestItem(name, strDescription, strQuery, author:strAuthor, input: strEnv);
                   }
                 }
                 else {
                   this.testQueue[name] = new TestItem(name, strDescription, strQuery, author:strAuthor);
                 }

                 //result
                 xml.XmlElement res = getElementByName(e, 'result');
                 if (res != null) {
                   xml.XmlElement any = getElementByName(res,'any-of');
                   if(any != null){ //more than one result
                     any.children.where((x)=>x is xml.XmlElement).forEach((xml.XmlElement x){
                       switchResultType(x, name);
                     });
                   }
                   else { //one result
                     xml.XmlElement resElem = res.children.firstWhere((x)=>x is xml.XmlElement,orElse:()=>null);
                     if(resElem!=null){
                       switchResultType(resElem, name);
                     }
                   }
                 }
               });
             }
         }
       });
     });

     return null;
   }

   void switchResultType(xml.XmlElement x, String name) {
     switch(x.name.local){
       case 'assert-true':
         this.testQueue[name].result.add(new ResultItem(ResultType.ASSERT_TRUE,null));
         break;
       case 'assert-false':
         this.testQueue[name].result.add(new ResultItem(ResultType.ASSERT_FALSE,null));
         break;
       case 'error':
         this.testQueue[name].result.add(new ResultItem(ResultType.ERROR,x.getAttribute('code')));
         break;
       case 'assert-xml':
         this.testQueue[name].result.add(new ResultItem(ResultType.ASSERT_XML,x.text));
         break;
       case 'assert-string-value':
         this.testQueue[name].result.add(new ResultItem(ResultType.ASSERT_STRING,x.text));
         break;
       case 'assert-empty':
         this.testQueue[name].result.add(new ResultItem(ResultType.ASSERT_EMPTY,null));
         break;
       case 'assert-count':
         this.testQueue[name].result.add(new ResultItem(ResultType.ASSERT_COUNT,x.text));
         break;
       case 'assert-eq':
         this.testQueue[name].result.add(new ResultItem(ResultType.ASSERT_EQ,x.text));
         break;
     }
   }

   xml.XmlElement getElementByName(xml.XmlElement parent, String name) {
     xml.XmlElement result = parent.children
         .firstWhere((y)=>y is xml.XmlElement && y.name.local == name,
         orElse:() => null);
     return result;
   }

}