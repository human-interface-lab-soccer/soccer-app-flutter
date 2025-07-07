import 'dart:async';
import 'package:flutter/services.dart';

class Provisioning {
  static const MethodChannel _methodChannel = MethodChannel(
    'human.mech.saitama-u.ac.jp/provisioningMethodChannel',
  );
  
  Future<void> startProvisioning(String uuid) async {
    await _methodChannel.invokeMethod('provisioning', {'uuid': uuid});
  }
}