import 'dart:async';
import 'dart:collection';
import 'package:flutter/services.dart';
import 'package:soccer_app_flutter/shared/models/ble_device.dart';

/// このクラスは、BLE（Bluetooth Low Energy）デバイスのスキャン機能を提供します。
///
/// ### 主な目的:
/// - BLEデバイスの検出およびリストアップを行い、アプリケーションで利用可能なデバイス情報を取得します。
///
/// ### 引数・戻り値:
/// - コンストラクタやメソッドの引数には、スキャン条件やコールバック関数などが含まれる場合があります。
/// - 戻り値として、検出されたBLEデバイスのリストやスキャン状態を返すことがあります。
///
/// ### 使用例:
/// ```dart
/// final scanner = GeneralBleScanner();
/// // ストリームを購読して、検出されたデバイスを取得
/// scanner.startScanning();
/// scanner.discoveredDevicesStream.listen((devices) {
///   for (var device in devices) {
///     print('Discovered device: ${device.name}, UUID: ${device.uuid}');
///   }
/// });
///
/// // スキャンを停止
/// scanner.stopScanning();
/// ```
///
/// ### 注意点:
/// - 実機での動作にはBluetoothの権限が必要です。
/// - スキャン中はバッテリー消費が増加する場合があります。
class GeneralBleScanner {
  static const EventChannel _eventChannel = EventChannel(
    'human.mech.saitama-u.ac.jp/scannerEventChannel',
  );
  static const MethodChannel _methodChannel = MethodChannel(
    'human.mech.saitama-u.ac.jp/scannerMethodChannel',
  );
  final List<BleDevice> _discoveredDevices = [];
  final _devicesController = StreamController<List<BleDevice>>.broadcast();

  final Queue<Function> _operationQueue = Queue<Function>();
  bool _isProcessingQueue = false;

  Stream<List<BleDevice>> get discoveredDevicesStream =>
      _devicesController.stream;
  List<BleDevice> get discoveredDevices => _discoveredDevices;
  StreamSubscription? _subscription;
  Timer? _cleanupTimer;

  final Duration _deviceTimeout = const Duration(seconds: 10);
  final Duration _cleanupInterval = const Duration(seconds: 5);

  void dispose() {
    stopScanning();
    _devicesController.close();
  }

  /// スキャンを開始し、デバイスの検出をリッスン
  Future<void> startScanning() async {
    await _methodChannel.invokeMethod('startScanning');
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      _onDeviceDiscovered,
      onError: _onScanError,
    );
    _startCleanupTimer();
  }

  /// スキャンを停止し、ストリームをキャンセル
  Future<void> stopScanning() async {
    await _methodChannel.invokeMethod('stopScanning');
    _subscription?.cancel();
    _subscription = null;
    _cleanupTimer?.cancel();
    _operationQueue.clear();
    _isProcessingQueue = false;
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      _enqueueOperation(_cleanupDevices);
    });
  }

  /// Queueに操作を追加して、順次処理
  void _enqueueOperation(Function operation) {
    _operationQueue.add(operation);
    _processQueue();
  }

  /// Queueの操作を処理
  void _processQueue() {
    if (_isProcessingQueue || _operationQueue.isEmpty) return;
    _isProcessingQueue = true;
    final operation = _operationQueue.removeFirst();
    operation();
    _isProcessingQueue = false;
    _processQueue();
  }

  /// 一定時間内に検出されなかったデバイスをリストから削除
  void _cleanupDevices() {
    // ストリームが閉じられている場合はタイマーをキャンセル
    if (_devicesController.isClosed) {
      _cleanupTimer?.cancel();
      return;
    }
    // 既にデバイスがない場合は何もしない
    if (_discoveredDevices.isEmpty) return;

    final DateTime now = DateTime.now();
    final updatedDevices =
        _discoveredDevices
            .where(
              (device) => now.difference(device.lastSeen) <= _deviceTimeout,
            )
            .toList();

    if (updatedDevices.length != _discoveredDevices.length) {
      discoveredDevices
        ..clear()
        ..addAll(updatedDevices);
      _devicesController.add(List.from(_discoveredDevices));
    }
  }

  /// デバイスが検出されたときのコールバック
  void _onDeviceDiscovered(dynamic device) {
    _enqueueOperation(() {
      // ストリームが閉じられている場合は何もしない
      if (_devicesController.isClosed) return;
      // デバイスがMapでない場合は何もしない
      if (device is! Map) return;

      BleDevice bleDevice = BleDevice.fromMap(
        Map<String, dynamic>.from(device),
      );
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
    });
  }

  /// スキャン中にエラーが発生したときの処理
  void _onScanError(dynamic error) {
    // ignore: avoid_print
    print("Scan error: $error");
  }
}
