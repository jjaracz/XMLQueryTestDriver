import 'result_item.dart';

class TestItem {
  String name;
  String set;
  String description;
  String author;
  String query;
  String input;
  List<ResultItem> result = [];
  TestItem(this.name, this.set, this.description, this.query,
      {this.input, this.author}) {}
}