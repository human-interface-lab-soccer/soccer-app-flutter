import 'dart:async';
import 'package:flutter/services.dart';

class Provisioning {
  static const MethodChannel _methodChannel = MethodChannel(
    'human.mech.saitama-u.ac.jp/provisioningMethodChannel',
  );
  static const EventChannel _eventChannel = EventChannel(
    'human.mech.saitama-u.ac.jp/provisioningEventChannel',
  );

  Stream<Map<String, dynamic>> get provisioningStream {
    return _eventChannel.receiveBroadcastStream().map(
      (dynamic event) => Map<String, dynamic>.from(event),
    );
  }

  /// メッシュプロビジョニングを開始するメソッド
  Future<Map<String, dynamic>> startProvisioning(String uuid) async {
    final response = await _methodChannel.invokeMethod('provisioning', {
      'uuid': uuid,
    });
    bool isSuccess = response['isSuccess'] ?? false;
    String message = response['Body'] ?? 'No message provided';

    return {'isSuccess': isSuccess, 'message': message};
  }
}
