import 'dart:io';
import 'dart:async';
import 'package:xml/xml.dart' as xml;
import 'result_item.dart';
import 'result_type.dart';
import 'test_item.dart';


class TestDriver {
  List<String> tests = [];
  Map<String, TestItem> testQueue = {};

  var contentRootPath = 'lib/res/qt3_1_0/';

  TestDriver();
  //TODO: make res folder accessible from another library where this lib is a dependency
  TestDriver.resources(String this.contentRootPath);

  ///xml list of required tests in the form of
  ///<tests><set>[set name]</set>...</tests>
  dynamic setup(path) async {
    var strXml = await new File('$path').readAsString();
    var doc = xml.parse(strXml);
    doc.rootElement.children
        .where((x) => x is xml.XmlElement)
        .forEach((xml.XmlElement e) {
      tests.add(e.text);
    });

    //for each test line
    //1. get the line in the catalog
    //2. get the source file
    tests.forEach((s) => print(s));
    return null;
  }

  Future buildTestCases() async {
    Completer completer = new Completer();
    var strXml = await new File('${contentRootPath}catalog.xml').readAsString();
    var doc = xml.parse(strXml);
    Future processing = processList(doc, strXml);
    processing.then((_){
      completer.complete(null);
    });
    return completer.future;
  }

  Future processList(xml.XmlDocument doc, String strXml) async {
    Completer completer = new Completer();
    var count = tests.length;
    var i = 0;
    tests.forEach((set) async {
      await processSet(doc, set, strXml);
      if(++i == count){
         completer.complete(null);
      }
    });
    return completer.future;
  }

  Future processSet(xml.XmlDocument doc, String set, strXml) async {
    Completer completer = new Completer();
    doc.rootElement.children
        .where((x) => x is xml.XmlElement)
        .forEach((xml.XmlElement e) async {
      if (set == e.getAttribute('name')) {
        //print('${e.name.local} ${e.getAttribute('name')}');
        var file = e.getAttribute('file');
        if (file == null) return null;
        strXml = await new File('${contentRootPath}$file').readAsString();
        //print('${contentRootPath}$file = $strXml');
        if (strXml != null && strXml != '') {
          var testCaseDoc = xml.parse(strXml);
          var count =  testCaseDoc.rootElement.children
              .where((x) => x is xml.XmlElement && x.name.local == 'test-case')
              .length;
          var i = 0;
          testCaseDoc.rootElement.children
              .where((x) => x is xml.XmlElement && x.name.local == 'test-case')
              .forEach((xml.XmlElement y) async {
                 var name = y.getAttribute('name');
                 await processTest(y, name, set);
                 if(++i == count && !(completer.isCompleted)){
                   completer.complete(null);
                 }
              });
        }
      }
    });
    return completer.future;
  }

  Future processTest(xml.XmlElement y, String name, String set) async {

    Completer completer = new Completer();
    xml.XmlElement query = getElementByName(y, 'test');
    var strQuery;
    if (query != null) {
      strQuery = query.text;
    }

    //author
    xml.XmlElement author = getElementByName(y, 'created');
    var strAuthor;
    if (author != null) {
      strAuthor = author.getAttribute('by');
    }

    //description
    xml.XmlElement description = getElementByName(y, 'description');
    var strDescription;
    if (description != null) {
      strDescription = description.text;
    }

    //environment
    xml.XmlElement env = getElementByName(y, 'environment');
    if (env != null) {
      //get the source doc
      var ref = env.getAttribute('ref');
      var strEnv;
      try {
        strEnv = await new File('${contentRootPath}docs/${ref}.xml').readAsString();
      } catch (ex) {
        var envSource = env.findElements('source');
        if (envSource != null && envSource.length > 0) {
          try {
            ref = envSource[0].getAttribute("file");
            strEnv = await new File('${contentRootPath}prod/${ref}').readAsString();
          } catch (ex) {
            print('error reading environment file (2): $ex');
          }
        }
      }
      if (strEnv != null) {
        this.testQueue[name] = new TestItem(
            name, set, strDescription, strQuery,
            author: strAuthor, input: strEnv);
      }
    } else {
      this.testQueue[name] = new TestItem(
          name, set, strDescription, strQuery,
          author: strAuthor);
    }

    //result
    xml.XmlElement res = getElementByName(y, 'result');
    if (res != null) {
      xml.XmlElement any = getElementByName(res, 'any-of');
      if (any != null) {
        //more than one accepted result
        any.children
            .where((x) => x is xml.XmlElement)
            .forEach((xml.XmlElement x) {
          switchResultType(x, name);
        });
      } else {
        //one result
        xml.XmlElement resElem = res.children.firstWhere(
                (x) => x is xml.XmlElement,
            orElse: () => null);
        if (resElem != null) {
          switchResultType(resElem, name);
        }
      }
    }

    completer.complete(null);
    return completer.future;
  }

  void switchResultType(xml.XmlElement x, String name) {
    if (this.testQueue[name] == null) {
      return;
    }
    switch (x.name.local) {
      case 'assert-true':
        this
            .testQueue[name]
            .result
            .add(new ResultItem(ResultType.ASSERT_TRUE, null));
        break;
      case 'assert-false':
        this
            .testQueue[name]
            .result
            .add(new ResultItem(ResultType.ASSERT_FALSE, null));
        break;
      case 'error':
        this
            .testQueue[name]
            .result
            .add(new ResultItem(ResultType.ERROR, x.getAttribute('code')));
        break;
      case 'assert-xml':
        this
            .testQueue[name]
            .result
            .add(new ResultItem(ResultType.ASSERT_XML, x.text));
        break;
      case 'assert-string-value':
        this
            .testQueue[name]
            .result
            .add(new ResultItem(ResultType.ASSERT_STRING, x.text));
        break;
      case 'assert-empty':
        this
            .testQueue[name]
            .result
            .add(new ResultItem(ResultType.ASSERT_EMPTY, null));
        break;
      case 'assert-count':
        this
            .testQueue[name]
            .result
            .add(new ResultItem(ResultType.ASSERT_COUNT, x.text));
        break;
      case 'assert-eq':
        this
            .testQueue[name]
            .result
            .add(new ResultItem(ResultType.ASSERT_EQ, x.text));
        break;
    }
  }

  xml.XmlElement getElementByName(xml.XmlElement parent, String name) {
    xml.XmlElement result = parent.children.firstWhere(
        (y) => y is xml.XmlElement && y.name.local == name,
        orElse: () => null);
    return result;
  }

  String executeTest(TestItem test, doXMLQuery(query, input)){
    String result = 'false';
    int count = 0;
    test.result.forEach((r){
      count++;
      switch(r.type){
        case ResultType.ASSERT_EQ:
         if(r.value == doXMLQuery(test.query,test.input)) result = 'tested true OK';
         else result = 'tested false';
         break;
        default: result = 'test result type not supported';
      }
    });
    if(count == 0) result = 'no query result provided';
    return  '${test.set}?${test.name} ran with result => $result';
  }


}
