import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_app_flutter/features/platform_channels/general_ble_scanner.dart';
import 'package:soccer_app_flutter/shared/model/ble_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel scannerMethodChannel = MethodChannel(
    'human.mech.saitama-u.ac.jp/scannerMethodChannel',
  );
  const EventChannel scannerEventChannel = EventChannel(
    'human.mech.saitama-u.ac.jp/scannerEventChannel',
  );

  group('GeneralBleScanner', () {
    late GeneralBleScanner scanner;
    bool isScannerActive = false;

    setUp(() {
      scanner = GeneralBleScanner();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(scannerMethodChannel, (
            MethodCall methodCall,
          ) async {
            switch (methodCall.method) {
              case 'startScanning':
                isScannerActive = true;
                return null;
              case 'stopScanning':
                isScannerActive = false;
                return null;
              default:
                throw MissingPluginException(
                  'Method not implemented: ${methodCall.method}',
                );
            }
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(scannerEventChannel, null);
    });

    tearDown(() {
      scanner.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(scannerMethodChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(scannerEventChannel, null);
    });

    test('startScanning calls method channel', () async {
      await scanner.startScanning();
      expect(isScannerActive, isTrue);
    });

    test('stopScanning calls method channel', () async {
      await scanner.stopScanning();
      expect(isScannerActive, isFalse);
    });

    test('discoveredDevicesStreamでBLEデバイスが受信できる', () async {
      // テスト用のBLEデバイスデータ
      final testDevice =
          BleDevice(
            name: 'Test Device 1',
            uuid: '12345678-1234-5678-1234-567812345678',
            rssi: -50,
            lastSeen: DateTime(2001, 12, 28), // 2001年12月28日 (野澤の誕生日)
          ).toMap();

      // イベントチャンネルのモックストリームハンドラーを設定
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            scannerEventChannel,
            MockStreamHandler.inline(
              onListen: (Object? arguments, MockStreamHandlerEventSink events) {
                // 100ms後にテストデバイスを発見したイベントを送信
                Future.delayed(Duration(milliseconds: 100), () {
                  events.success(testDevice);
                });
              },
              onCancel: (Object? arguments) {},
            ),
          );

      // スキャンを開始してストリームを取得
      await scanner.startScanning();
      final stream = scanner.discoveredDevicesStream;

      // ストリームからの最初の値を待機
      final deviceList = await stream.first;
      expect(deviceList, isA<List<BleDevice>>());
      expect(deviceList[0].name, "Test Device 1");
      expect(deviceList[0].uuid, "12345678-1234-5678-1234-567812345678");
      expect(deviceList[0].rssi, -50);
      expect(deviceList[0].lastSeen, DateTime(2001, 12, 28));
    });
  });
}
