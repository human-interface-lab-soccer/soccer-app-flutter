import 'dart:async';
import 'package:flutter/services.dart';

class Provisioning {
  static const MethodChannel _methodChannel = MethodChannel(
    'human.mech.saitama-u.ac.jp/provisioningMethodChannel',
  );

  Future<bool> startProvisioning(String uuid) async {
    final response = await _methodChannel.invokeMethod('provisioning', {
      'uuid': uuid,
    });
    bool isSuccess = response['isSuccess'] ?? false;
    String message = response['Body'] ?? 'No message provided';
    if (isSuccess) {
      // ignore: avoid_print
      print('Provisioning successful: $message');
    } else {
      // ignore: avoid_print
      print('Provisioning failed: $message');
    }
    return isSuccess;
  }
}
