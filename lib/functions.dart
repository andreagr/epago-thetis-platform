import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveDataAsCSV(
    List<dynamic> data, String sensorName, DateTime start, DateTime end) async {
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

  final directory = await getApplicationDocumentsDirectory();
  final path = directory.path;
  final file = File(
      '$path\\${sensorName}_${start.toLocal().toString().split(' ')[0]}_${end.toLocal().toString().split(' ')[0]}_data.csv');
  await file.writeAsString(csv);

  print('CSV file saved at: ${file.path}');
  return file.path;
}
