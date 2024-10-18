import 'dart:convert';
import 'dart:html' as html;

import 'package:csv/csv.dart';

Future<void> saveDataAsCSV(List<Map<String, dynamic>> data, String sensorName,
    DateTime start, DateTime end) async {
  List<List<dynamic>> csvData = [
    ['id', 'sensor_name', 'temperature', 'humidity', 'timestamp', 'topic']
  ];

  for (var item in data) {
    csvData.add([
      item['id'],
      item['sensor_name'],
      item['temperature'],
      item['humidity'],
      item['timestamp'],
      item['topic']
    ]);
  }

  String csv = const ListToCsvConverter().convert(csvData);

  final bytes = utf8.encode(csv);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download",
        "${sensorName}_${start.toLocal()}_${end.toLocal()}_data.csv")
    ..click();

  html.Url.revokeObjectUrl(url);
}
