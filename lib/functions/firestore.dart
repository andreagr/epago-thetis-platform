import 'package:firedart/firestore/firestore.dart';
import 'package:firedart/firestore/models.dart';
import 'package:thethis_platform/classes/device.dart';

Future<List<Device>> fetchDevices() async {
  List<Device> devices = [];

  // Reference to the Firestore collection
  //CollectionReference deviceCollection =
  //   Firestore.instance.collection('devices');

  // Fetch documents from the collection
  var map = await Firestore.instance.collection("devices").get();

  print(map);
  /*for (var doc in querySnapshot.docs) {
    // Assuming each device has two sensors
    List<Sensor> sensors = [
      Sensor(id: 'sensor_001', temperatureData: [], humidityData: []),
      Sensor(id: 'sensor_002', temperatureData: [], humidityData: []),
    ];

    // Create a Device object from the document data
    Device device = Device(
      deviceId: doc.id,
      deviceOwnerId: doc['deviceOwnerId'],
      imageUrl: doc['imageUrl'],
      name: doc['name'],
      placementId: doc['placementId'],
      placementNumber: doc['placementNumber'],
      sensors: sensors,
    );

    devices.add(device);
  }*/

  return devices;
}
