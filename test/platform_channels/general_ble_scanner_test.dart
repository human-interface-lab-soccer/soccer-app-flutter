import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_app_flutter/features/platform_channels/general_ble_scanner.dart';

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
    bool startScanningCalled = false;
    bool stopScanningCalled = false;

    setUp(() {
      startScanningCalled = false;
      stopScanningCalled = false;
      scanner = GeneralBleScanner();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(scannerMethodChannel, (
            MethodCall methodCall,
          ) async {
            switch (methodCall.method) {
              case 'startScanning':
                startScanningCalled = true;
                return null;
              case 'stopScanning':
                stopScanningCalled = true;
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
      // TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      //     .setMockMethodCallHandler(scannerMethodChannel, null);
      // TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      //     .setMockStreamHandler(scannerEventChannel, null);
    });

    test('startScanning calls method channel', () async {
      expect(startScanningCalled, isFalse);
      await scanner.startScanning();
      expect(startScanningCalled, isTrue);
      expect(stopScanningCalled, isFalse);
    });
    test('stopScanning calls method channel', () async {
      expect(stopScanningCalled, isFalse);
      await scanner.stopScanning();
      expect(stopScanningCalled, isTrue);
      expect(startScanningCalled, isFalse);
    });
  });
}
