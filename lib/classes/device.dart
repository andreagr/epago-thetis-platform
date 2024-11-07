class Device {
  final String deviceId;
  final String deviceOwnerId;
  final String imageUrl;
  final String name;
  final String placementId;
  final int placementNumber;
  final List<Sensor> sensors;

  Device({
    required this.deviceId,
    required this.deviceOwnerId,
    required this.imageUrl,
    required this.name,
    required this.placementId,
    required this.placementNumber,
    required this.sensors,
  });
}

class Sensor {
  final String id;
  final List<double> temperatureData;
  final List<double> humidityData;

  Sensor({
    required this.id,
    required this.temperatureData,
    required this.humidityData,
  });
}
