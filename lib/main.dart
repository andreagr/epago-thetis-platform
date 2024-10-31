import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mqtt_client_manager.dart'
    if (dart.library.html) 'mqtt_client_manager_web.dart';
import 'functions.dart' if (dart.library.html) 'functions_web.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
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
  late MqttClientManager mqttClientManager;
  int dataCounter = 0;
  bool loading = false;

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
  ];

  @override
  void initState() {
    super.initState();
    mqttClientManager = MqttClientManager(
      'a36s11e5lf5q7h-ats.iot.us-east-1.amazonaws.com',
      'dashboard',
      onMessageReceived: _handleMessageReceived,
    );
    _connectMqtt();
  }

  Future<void> _connectMqtt() async {
    await mqttClientManager.connect();
    mqttClientManager.subscribe('publish/50351769a907f18');
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

      for (var key in data.keys) {
        sensorDataList.add({
          'sensorId': 'Donatello',
          'h': data[key]['h'].toDouble(),
          't': data[key]['t'].toDouble(),
        });
      }

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
        title: Text('Thetis - Cloud Monitoring Platform'),
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
                  _buildLineChartSection(),
                  SizedBox(height: 20),
                  //_buildHumiditySetters(),
                  //SizedBox(height: 20),
                  //_buildReceivedMessagesSection(),
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

  Widget _buildTodayHighlightsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildHighlightItem('Precipitation', '2%'),
            _buildHighlightItem('Humidity', '87%'),
            _buildHighlightItem('Wind', '0 km/h'),
            _buildHighlightItem('Sunrise & Sunset', '6:18 am / 7:27 pm'),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLineChartSection() {
    return Card(
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
                          spots: sensor.temperatureData,
                          color: Color.fromARGB(255, 164, 50, 50),
                          barWidth: 2,
                          belowBarData: BarAreaData(show: false),
                        ),
                        LineChartBarData(
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Received Messages',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: receivedMessages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(receivedMessages[index]),
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
      // Here you would typically fetch data for the selected date range
      print(
          'Selected date range for $sensorName: ${picked.start} to ${picked.end}');
      setState(() {
        loading = true;
      });
      await _getDataByDateRange(sensorName, picked.start, picked.end);
      setState(() {
        loading = false;
      });
    }
  }
}

Future<void> _selectDateRange(BuildContext context, String sensorName) async {
  final DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2022),
    lastDate: DateTime.now(),
    initialDateRange: DateTimeRange(
      start: DateTime.now().subtract(Duration(days: 7)),
      end: DateTime.now(),
    ),
  );

  if (picked != null) {
    // Call the Firebase function to get data for the selected date range
    await _getDataByDateRange(sensorName, picked.start, picked.end);
  }
}

Future<void> _getDataByDateRange(
    String sensorName, DateTime start, DateTime end) async {
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

      await saveDataAsCSV(data['data'], sensorName, start, end);
    } else {
      print('Failed to fetch data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching data: $e');
  }
}
