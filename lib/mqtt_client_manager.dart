import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttClientManager {
  final String server;
  final String clientIdentifier;
  final Function(String) onMessageReceived;
  final Function(String) onLog; // New logging callback

  late MqttServerClient _client;

  MqttClientManager(this.server, this.clientIdentifier,
      {required this.onMessageReceived, required this.onLog});

  Future<void> connect() async {
    _client = MqttServerClient.withPort(server, clientIdentifier, 8883);
    _client.secure = true;
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;

    String certPath = kDebugMode ? 'assets' : 'data';

    final context = SecurityContext.defaultContext;
    context.setClientAuthorities('$certPath/AmazonRootCA1.pem');
    context.useCertificateChain('$certPath/device.pem.crt');
    context.usePrivateKey('$certPath/private.pem.key');

    _client.securityContext = context;

    try {
      await _client.connect();
    } catch (e) {
      onLog('Exception: $e');
      _client.disconnect();
    }

    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);
      onMessageReceived(payload);
    });
  }

  void subscribe(String topic) {
    try {
      _client.subscribe(topic, MqttQos.atLeastOnce);
    } catch (e) {
      print("error in subscribing " + e.toString());
    }
  }

  void disconnect() {
    _client.disconnect();
  }

  void _onDisconnected() {
    onLog('Disconnected');
  }

  void _onConnected() {
    onLog('Connected');
  }

  void _onSubscribed(String topic) {
    onLog('Subscribed to $topic');
  }

  void publish(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }
}
