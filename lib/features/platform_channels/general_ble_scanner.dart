import 'dart:async';
import 'package:flutter/services.dart';
import 'package:soccer_app_flutter/shared/model/ble_device.dart';

/// A class to manage Bluetooth Low Energy (BLE) scanning using platform channels.
class GeneralBleScanner {
  static const EventChannel _channel = EventChannel(
    'human.mech.saitama-u.ac.jp/generalBleScanner',
  );
  final List<BleDevice> _discoveredDevices = [];
  final _devicesController = StreamController<List<BleDevice>>.broadcast();

  Stream<List<BleDevice>> get discoveredDevicesStream =>
      _devicesController.stream;
  List<BleDevice> get discoveredDevices => _discoveredDevices;
  StreamSubscription? _subscription;

  GeneralBleScanner() {
    _startStream();
  }

  void dispose() {
    _subscription?.cancel();
    _devicesController.close();
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
    if (_discoveredDevices.any((d) => d.uuid == bleDevice.uuid)) {
      // 既に同じUUIDのデバイスがリストに存在する場合は上書き
      int index = _discoveredDevices.indexWhere(
        (d) => d.uuid == bleDevice.uuid,
      );
      _discoveredDevices[index] = bleDevice;
    } else {
      _discoveredDevices.add(bleDevice);
    }
    _devicesController.add(List<BleDevice>.from(_discoveredDevices));
  }

  void _onScanError(dynamic error) {
    // スキャン中にエラーが発生したときの処理
    print("Scan error: $error");
  }
}
