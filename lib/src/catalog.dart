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
  TestItem(this.name, this.description, this.query,
      {this.input, this.author}) {}
}

class Catalog {
  List<String> tests = [];
  Map<String, TestItem> testQueue = {};

  var contentRootPath = 'res/qt3_1_0/';

  ///xml list of required tests in the form of
  ///<tests><set>[set name]</set>...</tests>
  void setup(path) {
    var temp = '''<tests>
                      <set>prod-AxisStep</set>
                      <set>prod-AxisStep.ancestor</set>
                      <set>prod-AxisStep.following</set>
                   </tests>''';
    var doc = xml.parse(temp);
    doc.rootElement.children
        .where((x) => x is xml.XmlElement)
        .forEach((xml.XmlElement e) {
      tests.add(e.text);
    });

    //for each test line
    //1. get the line in the catalog
    //2. get the source file
    tests.forEach((s) => print(s));
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
    tests.forEach((t) async {
      await processSet(doc, t, strXml);
      if(++i == count){
         completer.complete(null);
      }
    });
    return completer.future;
  }

  Future processSet(xml.XmlDocument doc, String t, strXml) async {
    Completer completer = new Completer();
    doc.rootElement.children
        .where((x) => x is xml.XmlElement)
        .forEach((xml.XmlElement e) async {
      if (t == e.getAttribute('name')) {
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
                 await processTest(y, name);
                 if(++i == count){
                   completer.complete(null);
                 }
              });
        }
      }
    });
    return completer.future;
  }

  Future processTest(xml.XmlElement y, String name) async {

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

    //result
    xml.XmlElement res = getElementByName(y, 'result');
    if (res != null) {
      xml.XmlElement any = getElementByName(res, 'any-of');
      if (any != null) {
        //more than one result
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
            name, strDescription, strQuery,
            author: strAuthor, input: strEnv);
        completer.complete(null);
      }
    } else {
      this.testQueue[name] = new TestItem(
          name, strDescription, strQuery,
          author: strAuthor);
      completer.complete(null);
    }

    if(this.testQueue[name]==null) completer.complete(null);
    return completer.future;
  }

  void switchResultType(xml.XmlElement x, String name) {
    if (this.testQueue[name] == null) {
      print("Error: Missing test = $name");
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
}
