import 'package:flutter/material.dart';

// Conditional import
import 'mqtt_client_manager.dart'
    if (dart.library.html) 'mqtt_client_manager_web.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> messages = [];
  late MqttClientManager mqttClientManager;

  @override
  void initState() {
    super.initState();
    mqttClientManager = MqttClientManager(
      'a36s11e5lf5q7h-ats.iot.us-east-1.amazonaws.com',
      'dashboard',
      onMessageReceived: (message) {
        setState(() {
          messages.add(message);
        });
      },
    );
    _connectMqtt();
  }

  Future<void> _connectMqtt() async {
    await mqttClientManager.connect();
    mqttClientManager.subscribe('arduino/simple');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MQTT Messages'),
      ),
      body: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(messages[index]),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    mqttClientManager.disconnect();
    super.dispose();
  }
}
