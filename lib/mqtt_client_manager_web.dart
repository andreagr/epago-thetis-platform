import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttClientManager {
  final String server;
  final String clientIdentifier;
  final Function(String) onMessageReceived;
  late MqttBrowserClient _client;

  MqttClientManager(this.server, this.clientIdentifier,
      {required this.onMessageReceived});

  Future<void> connect() async {
    final wsUrl = 'ws://$server:443';

    _client = MqttBrowserClient.withPort(wsUrl, clientIdentifier, 443);
    _client.logging(on: true);
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;
    _client.websocketProtocols = ['mqtt'];

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean();
    _client.connectionMessage = connMessage;

    try {
      await _client.connect();
    } catch (e) {
      print('Exception: $e');
      _client.disconnect();
    }

    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT client connected');
      _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);
        onMessageReceived(payload);
      });
    }
  }

  void subscribe(String topic) {
    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      _client.subscribe(topic, MqttQos.atLeastOnce);
    } else {
      print('MQTT client is not connected. Cannot subscribe.');
    }
  }

  void disconnect() {
    _client.disconnect();
  }

  void _onDisconnected() {
    print('MQTT client disconnected');
  }

  void _onConnected() {
    print('MQTT client connected');
  }

  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic $topic');
  }

  void publish(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }
}
