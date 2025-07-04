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
///   'lastSeen': DateTime.now(),
/// });
/// print(device); // BleDevice(name: My Device, uuid: XXXX-XXXX, rssi: -70, lastSeen: 2025-06-26 19:12:34.567)
/// ```
///
class BleDevice {
  final String name;
  final String uuid;
  final int rssi;
  final DateTime lastSeen;

  BleDevice({
    required this.name,
    required this.uuid,
    required this.rssi,
    required this.lastSeen,
  });

  factory BleDevice.fromMap(Map<String, dynamic> map) {
    return BleDevice(
      name: map['name'] as String? ?? 'Unknown Device',
      uuid: map['uuid'] as String? ?? 'Unknown Address',
      rssi: map['rssi'] as int? ?? 0,
      lastSeen: map["lastSeen"] != null 
          ? DateTime.parse(map["lastSeen"] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'uuid': uuid,
      'rssi': rssi,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'BleDevice(name: $name, uuid: $uuid, rssi: $rssi)';
  }

  BleDevice copyWith({
    String? name,
    String? uuid,
    int? rssi,
    DateTime? lastSeen,
  }) {
    return BleDevice(
      name: name ?? this.name,
      uuid: uuid ?? this.uuid,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
