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
  Timer? _cleanupTimer;

  final Duration _deviceTimeout = const Duration(seconds: 30);
  final Duration _cleanupInterval = const Duration(seconds: 5);

  GeneralBleScanner() {
    _startStream();
    _startCleanupTimer();
  }

  void dispose() {
    _subscription?.cancel();
    _devicesController.close();
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _cleanupTimer?.cancel();
  }

  void restart() {
    _startStream();
    _startCleanupTimer();
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      _cleanupDevices();
    });
  }

  void _cleanupDevices() {
    if (_devicesController.isClosed) {
      // ストリームが閉じられている場合はタイマーをキャンセル
      _cleanupTimer?.cancel();
      return;
    }
    if (_discoveredDevices.isEmpty) {
      return; // 既にデバイスがない場合は何もしない
    }

    final DateTime now = DateTime.now();
    final updatedDevices = _discoveredDevices
      .where((device) => now.difference(device.lastSeen) <= _deviceTimeout)
      .toList();
    
    if (updatedDevices.length != _discoveredDevices.length) {
      discoveredDevices
        ..clear()
        ..addAll(updatedDevices);
      _devicesController.add(List.from(_discoveredDevices));
    }
  }

  void _startStream() {
    _subscription = _channel.receiveBroadcastStream().listen(
      _onDeviceDiscovered,
      onError: _onScanError,
    );
  }

  void _onDeviceDiscovered(dynamic device) {
    // ストリームが閉じられている場合は何もしない
    if (_devicesController.isClosed) return;

    // デバイスがMapでない場合は何もしない
    if (device is! Map) return;

    BleDevice bleDevice = BleDevice.fromMap(Map<String, dynamic>.from(device));
    if (_discoveredDevices.any((d) => d.uuid == bleDevice.uuid)) {
      // 既に同じUUIDのデバイスがリストに存在する場合は上書き
      int index = _discoveredDevices.indexWhere(
        (d) => d.uuid == bleDevice.uuid,
      );
      _discoveredDevices[index] = bleDevice.copyWith(
        lastSeen: DateTime.now(),
      );
    } else {
      // 新しいデバイスをリストに追加
      _discoveredDevices.add(bleDevice);
    }
    _devicesController.add(List<BleDevice>.from(_discoveredDevices));
  }

  void _onScanError(dynamic error) {
    // スキャン中にエラーが発生したときの処理
    // ignore: avoid_print
    print("Scan error: $error");
  }
}
