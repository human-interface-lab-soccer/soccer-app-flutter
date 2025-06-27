import 'dart:async';
import 'package:flutter/services.dart';

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

/// A class to manage Bluetooth Low Energy (BLE) scanning using platform channels.
class GeneralBleScanner {
  static const EventChannel _channel = EventChannel(
    'human.mech.saitama-u.ac.jp/generalBleScanner',
  );
  List<BleDevice> discoveredDevices = [];
  StreamSubscription? _subscription;

  GeneralBleScanner() {
    _startStream();
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _startStream() {
    _subscription = _channel.receiveBroadcastStream().listen(
      _onDeviceDiscovered,
      onError: _onScanError,
    );
  }

  void _onDeviceDiscovered(dynamic device) {
    if (device is! Map) {
      return;
    }
    BleDevice bleDevice = BleDevice.fromMap(Map<String, dynamic>.from(device));
    if (discoveredDevices.any((d) => d.uuid == bleDevice.uuid)) {
      // 既に同じUUIDのデバイスがリストに存在する場合は上書き
      int index = discoveredDevices.indexWhere((d) => d.uuid == bleDevice.uuid);
      discoveredDevices[index] = bleDevice;
    } else {
      discoveredDevices.add(bleDevice);
    }
  }

  void _onScanError(dynamic error) {
    // スキャン中にエラーが発生したときの処理
    print("Scan error: $error");
  }
}
