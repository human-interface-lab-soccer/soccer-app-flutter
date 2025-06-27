/// Bluetoothデバイスの情報を表すクラス
///
/// このクラスは、BLEデバイスの名前、UUID、およびRSSIを保持します。
///
/// example:
/// ```dart
/// var device = BleDevice.fromMap({
///   'name': 'My Device',
///   'uuid': 'XXXX-XXXX',
///   'rssi': -70,
/// });
/// print(device); // BleDevice(name: My Device, uuid: XXXx-XXXX, rssi: -70)
/// ```
///
class BleDevice {
  final String name;
  final String uuid;
  final int rssi;

  BleDevice({required this.name, required this.uuid, required this.rssi});

  factory BleDevice.fromMap(Map<String, dynamic> map) {
    return BleDevice(
      name: map['name'] as String? ?? 'Unknown Device',
      uuid: map['uuid'] as String? ?? 'Unknown Address',
      rssi: map['rssi'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'BleDevice(name: $name, uuid: $uuid, rssi: $rssi)';
  }
}
