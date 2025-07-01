import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_app_flutter/features/platform_channels/general_ble_scanner.dart';

void main() {
  const MethodChannel methodChannel = MethodChannel(
    'human.mech.saitama-u.ac.jp/scannerMethodChannel',
  );
  const EventChannel eventChannel = EventChannel(
    'human.mech.saitama-u.ac.jp/scannerEventChannel',
  );

  group('GeneralBleScanner', () {
    late GeneralBleScanner scanner;

    setUp(() {
      scanner = GeneralBleScanner();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (
            MethodCall methodCall,
          ) async {
            switch (methodCall.method) {
              case 'startScanning':
                return null;
              case 'stopScanning':
                return null;
              default:
                throw MissingPluginException(
                  'Method not implemented: ${methodCall.method}',
                );
            }
          });
    });

    tearDown(() {
      scanner.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(eventChannel, null);
    });
  });
}
