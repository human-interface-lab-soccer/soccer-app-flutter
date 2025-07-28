import 'dart:async';
import 'package:flutter/services.dart';

/// このクラスは、BLEデバイスのプロビジョニング機能を提供します。
///
/// ### 主な目的:
/// - BLEデバイスのプロビジョニングを行い、デバイスの設定や接続を管理します。
/// - プロビジョニングの進捗をリアルタイムで受け取り、UIに反映します。
///
/// ### 使用例:
/// ```dart
/// final provisioning = Provisioning();
/// provisioning.startProvisioning('device-uuid').then((result) {
///   if (result['isSuccess']) {
///     print('Provisioning successful: ${result['message']}');
///   } else {
///     print('Provisioning failed: ${result['message']}');
///   }
/// });
/// provisioning.provisioningStream.listen((data) {
///   print('Provisioning status: ${data['status']}, message: ${data['message']}');
/// });
/// });
///
/// ### 注意点:
/// - 実機での動作にはBluetoothの権限が必要です。
/// - プロビジョニング中は、デバイスの状態や接続が変化する可能性があります。
class Provisioning {
  static const MethodChannel _methodChannel = MethodChannel(
    'human.mech.saitama-u.ac.jp/provisioningMethodChannel',
  );
  static const EventChannel _eventChannel = EventChannel(
    'human.mech.saitama-u.ac.jp/provisioningEventChannel',
  );

  /// プロビジョニングの進捗を受け取るストリーム
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
