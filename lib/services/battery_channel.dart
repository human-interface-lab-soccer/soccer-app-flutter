import 'dart:async';
import 'package:flutter/services.dart';

class BatteryChannel {
  static const MethodChannel _channel = MethodChannel(
    'human.mech.saitama-u.ac.jp/battery',
  );

  /// Retrieves the current battery level.
  Future<int> getBatteryLevel() async {
    int result = -1; // Default value in case of an error
    try {
      result = await _channel.invokeMethod<int>('getBatteryLevel') ?? -1;
    } on PlatformException catch (e) {
      print(e.message);
    }
    return result;
  }
}
