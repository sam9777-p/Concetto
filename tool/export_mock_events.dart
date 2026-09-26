import 'dart:convert';
import 'dart:io';
import '../lib/core/network/mock_data.dart';

void main() {
  final list = MockData.events.map((e) {
    final map = e.toJson();
    map['_id'] = e.id;
    map['id'] = e.id;
    return map;
  }).toList();

  File('tool/events_data.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(list),
  );
  print('Successfully exported ${list.length} events with _id and id to tool/events_data.json');
}
