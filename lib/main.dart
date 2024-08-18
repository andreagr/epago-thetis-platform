import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'mqtt_client_manager.dart'
    if (dart.library.html) 'mqtt_client_manager_web.dart';
import 'dart:convert'; // Import JSON decoding library

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
      ),
      home: WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final List<FlSpot> temperatureData = [];
  final List<FlSpot> humidityData = [];
  final List<String> receivedMessages = []; // List to hold received messages
  late MqttClientManager mqttClientManager;
  final TextEditingController humidityController = TextEditingController();
  int dataCounter = 0;

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
    mqttClientManager.subscribe('arduino/simple');
  }

  void _handleMessageReceived(String message) {
    final data = parseMessage(message);
    if (data != null) {
      setState(() {
        temperatureData.add(FlSpot(dataCounter.toDouble(), data['t']));
        humidityData.add(FlSpot(dataCounter.toDouble(), data['h']));
        receivedMessages.add(message);
        dataCounter++;
      });
    }
  }

  Map<String, dynamic>? parseMessage(String message) {
    try {
      final Map<String, dynamic> data = json.decode(message);
      return {
        'sensorId': data['sensorId'],
        'h': data['h'].toDouble(),
        't': data['t'].toDouble(),
      };
    } catch (e) {
      print('Error parsing message: $e');
      return null;
    }
  }

  void _sendHumidityGoal() {
    final String goalHumidity = humidityController.text;
    if (goalHumidity.isNotEmpty) {
      mqttClientManager.publish('set/humidity', goalHumidity);
      humidityController.clear(); // Clear the input field after sending
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
        title: Text('Thetis Cloud Monitoring Platform'),
        //backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildCurrentWeatherSection(),
            SizedBox(height: 20),
            _buildTodayHighlightsSection(),
            SizedBox(height: 20),
            _buildLineChartSection(),
            SizedBox(height: 20),
            _buildHumidityForm(), // Add the form here

            SizedBox(height: 20),
            _buildReceivedMessagesSection(),
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
                'https://images.pexels.com/photos/3906604/pexels-photo-3906604.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', // Placeholder image asset
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
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donatello',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1601887389937-0b02c26b602c?q=80&w=2454&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', // Placeholder image asset
                          height: 200,
                          fit: BoxFit.cover,
                        ),
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
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Container(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      showTitles: true, reservedSize: 30),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      showTitles: true, reservedSize: 40),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: temperatureData,
                                  color: Colors.red,
                                  barWidth: 2,
                                  belowBarData: BarAreaData(show: false),
                                ),
                                LineChartBarData(
                                  spots: humidityData,
                                  color: Colors.blue,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),
            Container(
              width: 1,
              height: 200,
              color: Colors.white,
            ),
            SizedBox(width: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Girl with Flower',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1579783928621-7a13d66a62d1?q=80&w=2490&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', // Placeholder image asset
                          height: 200,
                          fit: BoxFit.cover,
                        ),
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
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Container(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      showTitles: true, reservedSize: 30),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      showTitles: true, reservedSize: 40),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: temperatureData,
                                  color: Colors.red,
                                  barWidth: 2,
                                  belowBarData: BarAreaData(show: false),
                                ),
                                LineChartBarData(
                                  spots: humidityData,
                                  color: Colors.blue,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildThreeDaysForecastSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildForecastItem('Tuesday', '26° ↑ / 11° ↓', Icons.wb_cloudy),
            Divider(),
            _buildForecastItem(
                'Wednesday', '22° ↑ / 11° ↓', Icons.beach_access),
            Divider(),
            _buildForecastItem('Thursday', '26° ↑ / 11° ↓', Icons.ac_unit),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(String day, String temperature, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: TextStyle(fontSize: 16),
        ),
        Row(
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 10),
            Text(temperature),
          ],
        ),
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

  Widget _buildHumidityForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Goal Humidity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: humidityController,
              decoration:
                  InputDecoration(labelText: 'Enter desired humidity (%)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendHumidityGoal,
              child: Text('Set Humidity'),
            ),
          ],
        ),
      ),
    );
  }
}
