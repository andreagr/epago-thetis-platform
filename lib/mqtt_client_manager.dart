import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttClientManager {
  final String server;
  final String clientIdentifier;
  final Function(String) onMessageReceived;
  late MqttServerClient _client;

  MqttClientManager(this.server, this.clientIdentifier,
      {required this.onMessageReceived});

  Future<void> connect() async {
    _client = MqttServerClient.withPort(server, clientIdentifier, 8883);
    _client.secure = true;
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;

    final context = SecurityContext.defaultContext;
    context.setClientAuthorities('assets/AmazonRootCA1.pem');
    context.useCertificateChain('assets/device.pem.crt');
    context.usePrivateKey('assets/private.pem.key');
    _client.securityContext = context;

    try {
      await _client.connect();
    } catch (e) {
      print('Exception: $e');
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
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void disconnect() {
    _client.disconnect();
  }

  void _onDisconnected() {
    print('Disconnected');
  }

  void _onConnected() {
    print('Connected');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }
}
