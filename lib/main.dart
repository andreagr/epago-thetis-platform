import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get_ip_address/get_ip_address.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'package:thethis_platform/functions/firestore.dart';
import 'mqtt_client_manager.dart'
    if (dart.library.html) 'mqtt_client_manager_web.dart';
import 'functions.dart' if (dart.library.html) 'functions_web.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firedart/firedart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  // Set the window title
  windowManager.setTitle("Epago Cloud Monitoring Platform");
  // Initialize Firebase
  //await Firebase.initializeApp();
  //FirebaseFirestore.instance.settings = const Settings(
  // persistenceEnabled: true,
  //);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thetis - Cloud Monitoring Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.figtreeTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF012463), // Main color for AppBar
          foregroundColor: Colors.white, // Text color for AppBar
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          headerBackgroundColor: Color(0xFF012463), // Main color for header
          headerForegroundColor: Colors.white, // Text color for header
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Color(0xFF0F59AA); // Accent color for selected day
            }
            return null; // Use default for other states
          }),
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white; // Text color for selected day
            }
            return null; // Use default for other states
          }),
          todayBackgroundColor: WidgetStateProperty.all(
              Color(0xFFE0E6F1)), // Light shade of main color for today
          todayForegroundColor: WidgetStateProperty.all(
              Color(0xFF012463)), // Main color for today's text
          rangeSelectionBackgroundColor: Color(0xFFE0E6F1).withOpacity(
              0.5), // Light shade of main color for range selection
          rangeSelectionOverlayColor: WidgetStateProperty.all(Color(0xFF0F59AA)
              .withOpacity(0.2)), // Accent color with opacity for range overlay
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: Colors.white,
          hourMinuteColor: Color(0xFFE0E6F1), // Light shade of main color
          hourMinuteTextColor: Color(0xFF012463), // Main color for text
          dialHandColor: Color(0xFF0F59AA), // Accent color for dial hand
          dialBackgroundColor: Color(
              0xFFE0E6F1), // Light shade of main color for dial background
          dialTextColor: Color(0xFF012463), // Main color for dial text
          entryModeIconColor:
              Color(0xFF0F59AA), // Accent color for entry mode icon
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, // Accent color for buttons
            foregroundColor: Color(0xFF0F59AA), // Text color for buttons
          ),
        ),
      ),
      home: WeatherHomePage(),
    );
  }
}

class Sensor {
  final String name;
  final String imageUrl;
  final List<FlSpot> temperatureData;
  final List<FlSpot> humidityData;
  final TextEditingController humidityController;

  Sensor({
    required this.name,
    required this.imageUrl,
    required this.temperatureData,
    required this.humidityData,
  }) : humidityController = TextEditingController();
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final List<String> receivedMessages = [];
  final List<String> logs = [];
  late MqttClientManager mqttClientManager;
  int dataCounter = 0;
  bool loading = false;
  String ipAddress = '';

  Map<String, String> idsMap = {
    '50351763a606718': 'Donatello',
    '5035176927f6618': 'Girl with Flower',
  };

  List<Sensor> sensors = [
    Sensor(
      name: 'Donatello',
      imageUrl:
          'https://images.unsplash.com/photo-1601887389937-0b02c26b602c?q=80&w=2454&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      temperatureData: [],
      humidityData: [],
    ),
    Sensor(
      name: 'Girl with Flower',
      imageUrl:
          'https://images.unsplash.com/photo-1579783928621-7a13d66a62d1?q=80&w=2490&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      temperatureData: [],
      humidityData: [],
    ),
    Sensor(
      name: 'Lady with an Ermine',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Dama_z_gronostajem.jpg/800px-Dama_z_gronostajem.jpg',
      temperatureData: [],
      humidityData: [],
    ),
    Sensor(
      name: 'Birth of Venus - Botticelli',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/6/61/El_nacimiento_de_Venus%2C_por_Sandro_Botticelli.jpg/1280px-El_nacimiento_de_Venus%2C_por_Sandro_Botticelli.jpg',
      temperatureData: [],
      humidityData: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    Firestore.initialize('epago-b4676');
    fetchDevices();
    mqttClientManager = MqttClientManager(
      'a36s11e5lf5q7h-ats.iot.us-east-1.amazonaws.com',
      ipAddress!,
      onMessageReceived: _handleMessageReceived,
      onLog: (log) {
        // Capture logs from MQTT manager
        setState(() {
          logs.add(log); // Add log to the list
        });
      },
    );
    _connectMqtt();
  }

  Future<void> _getIp() async {
    try {
      /// Initialize Ip Address
      IpAddress _ipAddress = IpAddress(type: RequestType.json);

      /// Get the IpAddress based on requestType.
      dynamic data = await _ipAddress.getIpAddress();
      print(data.toString());
      setState(() {
        ipAddress = data['ip'].toString();
      });
    } on IpAddressException catch (exception) {
      /// Handle the exception.
      print(exception.message);
    }
  }

  Future<void> _connectMqtt() async {
    await _getIp();

    try {
      await mqttClientManager.connect();
      mqttClientManager.subscribe('publish/+');
    } catch (e) {
      showAboutDialog(context: context, children: [Text(e.toString())]);
    }
  }

  void _handleMessageReceived(String message) {
    final List<Map<String, dynamic>>? data = parseMessage(message);
    if (data != null) {
      setState(() {
        for (var sensorData in data) {
          for (var sensor in sensors) {
            if (sensor.name == sensorData['sensorId']) {
              sensor.temperatureData
                  .add(FlSpot(dataCounter.toDouble(), sensorData['t']));
              sensor.humidityData
                  .add(FlSpot(dataCounter.toDouble(), sensorData['h']));
              if (sensor.humidityData.length > 100) {
                sensor.humidityData.removeAt(0);
                sensor.temperatureData.removeAt(0);
              }
              break; // Exit inner loop when matching sensor is found
            }
          }
        }
        receivedMessages.add(message);
        dataCounter++;
      });
    }
  }

  List<Map<String, dynamic>>? parseMessage(String message) {
    try {
      final Map<String, dynamic> data = json.decode(message);
      List<Map<String, dynamic>> sensorDataList = [];

      /*for (var key in data.keys) {
        if (key == 'deviceId') {
          continue;
        }
        sensorDataList.add({
          'deviceId': data['deviceId'],
          'sensorId': data['deviceId'] == '5035176927f6618'
              ? 'Donatello'
              : 'Girl with Flower',
          'h': data[key]['h'].toDouble(),
          't': data[key]['t'].toDouble(),
        });
      }*/

      String sensorId = 'Lady with an Ermine';
      if (data.containsKey('deviceId')) {
        sensorId = idsMap[data['deviceId']]!;
      }

      sensorDataList.add({
        'deviceId': data['deviceId'],
        'sensorId': sensorId,
        'h': (data['sensor1']['h'].toDouble() +
                data['sensor2']['h'].toDouble()) /
            2,
        't': (data['sensor1']['t'].toDouble() +
                data['sensor2']['t'].toDouble()) /
            2,
      });

      return sensorDataList; // Return a list of sensor data
    } catch (e) {
      print('Error parsing message: $e');
      return null;
    }
  }

  void _sendHumidityGoal(Sensor sensor) {
    final String goalHumidity = sensor.humidityController.text;
    if (goalHumidity.isNotEmpty) {
      mqttClientManager.publish('set/humidity/${sensor.name}', goalHumidity);
      sensor.humidityController.clear();
    }
  }

  @override
  void dispose() {
    mqttClientManager.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Epago Cloud Monitoring Platform'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            loading
                ? LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(8),
                  )
                : Container(),
            Expanded(
              child: ListView(
                children: [
                  _buildCurrentWeatherSection(),
                  //SizedBox(height: 20),
                  //_buildTodayHighlightsSection(),
                  SizedBox(height: 20),
                  _buildLineChartSection([sensors[0], sensors[1]]),
                  SizedBox(height: 20),
                  _buildLineChartSection([sensors[2], sensors[3]]),
                  //_buildHumiditySetters(),
                  //SizedBox(height: 20),
                  _buildReceivedMessagesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://images.pexels.com/photos/3906604/pexels-photo-3906604.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vatican Museums, Vatican City',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Monday, 07:43 AM',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Partly Cloudy',
                  style: TextStyle(fontSize: 14),
                ),
                Row(
                  children: [
                    Text(
                      '12°C',
                      style:
                          TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.wb_cloudy, size: 48),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartSection(List<Sensor> sensors) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildSensorBlock(sensors[0]),
            SizedBox(width: 20),
            Container(
              width: 1,
              height: 200,
              color: Colors.white,
            ),
            SizedBox(width: 20),
            _buildSensorBlock(sensors[1]),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorBlock(Sensor sensor) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sensor.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  sensor.imageUrl,
                  height: 200,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _selectDateRange(context, sensor.name),
                child: Text('Select Date Range'),
              ),
            ],
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temperature and Humidity Over Time',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Container(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 30),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 40),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          show: sensor.temperatureData.isNotEmpty,
                          spots: sensor.temperatureData,
                          color: Color.fromARGB(255, 164, 50, 50),
                          barWidth: 2,
                          belowBarData: BarAreaData(show: false),
                        ),
                        LineChartBarData(
                          show: sensor.humidityData.isNotEmpty,
                          spots: sensor.humidityData,
                          color: const Color.fromARGB(255, 20, 89, 146),
                          barWidth: 2,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Colors.red, 'Temperature'),
                    SizedBox(width: 20),
                    _buildLegendItem(Colors.blue, 'Humidity'),
                  ],
                ),
                _buildSensorHumiditySetter(sensor)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildHumiditySetters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Goal Humidity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...sensors
                .map((sensor) => _buildSensorHumiditySetter(sensor))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorHumiditySetter(Sensor sensor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: sensor.humidityController,
                decoration:
                    InputDecoration(labelText: 'Update target humidity (%)'),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _sendHumidityGoal(sensor),
              child: Text('Set'),
            ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildReceivedMessagesSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MQTT Log',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(logs[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, String sensorName) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    if (picked != null) {
      print(
          'Selected date range for $sensorName: ${picked.start} to ${picked.end}');
      setState(() {
        loading = true;
      });
      if (picked.end.difference(picked.start).inDays > 2) {
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('You can only select a range of up to 2 days.')),
        );
      } else {
        await _getDataByDateRange(
            context, sensorName, picked.start, picked.end);
      }
      setState(() {
        loading = false;
      });
    }
  }
}

Future<void> _getDataByDateRange(BuildContext context, String sensorName,
    DateTime start, DateTime end) async {
  try {
    // Convert dates to ISO 8601 format
    String startDate = start.toIso8601String();
    String endDate = end.toIso8601String();

    // Call the Firebase function
    final response = await http.get(Uri.parse(
        'https://us-central1-epago-b4676.cloudfunctions.net/getDataByDateRange?sensorName=$sensorName&startDate=$startDate&endDate=$endDate'));

    if (response.statusCode == 200) {
      // Parse the response and update the state
      final data = json.decode(response.body);
      //print(data);

      String savedPath =
          await saveDataAsCSV(data['data'], sensorName, start, end);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('File saved successfully'),
            content: Text(savedPath),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      print('Failed to fetch data: ${response.statusCode}');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to fetch data: ${response.statusCode}'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  } catch (e) {
    print('Error fetching data: $e');
  }
}
