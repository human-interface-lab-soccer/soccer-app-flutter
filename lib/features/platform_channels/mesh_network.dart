import 'dart:async';
import 'package:flutter/services.dart';
import 'package:soccer_app_flutter/shared/enums/led_color.dart';
import 'package:soccer_app_flutter/shared/models/mesh_node.dart';

class MeshNetwork {
  static const MethodChannel _methodChannel = MethodChannel(
    'human.mech.saitama-u.ac.jp/meshNetworkMethodChannel',
  );
  static const EventChannel _eventChannel = EventChannel(
    'human.mech.saitama-u.ac.jp/meshNetworkEventChannel',
  );

  static Future<List<MeshNode>> getNodeList() async {
    final response = await _methodChannel.invokeMethod('getNodeList');
    if (response is List) {
      return response.map((node) {
        return MeshNode.fromMap(Map<String, dynamic>.from(node));
      }).toList();
    } else {
      throw Exception('Failed to fetch node list');
    }
  }

  /// MeshNetworkのイベントストリームを取得
  static Stream<Map<String, dynamic>> get meshNetworkStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      } else {
        throw Exception('Invalid event data');
      }
    });
  }

  /// GenericOnOffSetの状態を変更するメソッド
  static Future<Map<String, dynamic>> genericOnOffSet({
    required int unicastAddress,
    required bool state,
  }) async {
    final response = await _methodChannel.invokeMethod('genericOnOffSet', {
      'unicastAddress': unicastAddress,
      'state': state,
    });
    bool isSuccess = response['isSuccess'] ?? false;
    String message = response['message'] ?? 'No message provided';
    return {'isSuccess': isSuccess, 'message': message};
  }

  /// GenericColorSetの状態を変更するメソッド
  static Future<Map<String, dynamic>> genericColorSet({
    required int unicastAddress,
    required int color,
  }) async {
    final response = await _methodChannel.invokeMethod('genericColorSet', {
      'unicastAddress': unicastAddress,
      'color': color,
    });
    bool isSuccess = response['isSuccess'] ?? false;
    String message = response['message'] ?? 'No message provided';
    return {'isSuccess': isSuccess, 'message': message};
  }

  /// colorをpublishするメソッド
  static Future<Map<String, dynamic>> publishColor({required int color}) async {
    final response = await _methodChannel.invokeMethod('publishColor', {
      'color': color,
    });
    bool isSuccess = response['isSuccess'] ?? false;
    String message = response['message'] ?? 'No message provided';
    return {'isSuccess': isSuccess, 'message': message};
  }

  /// 各ノードの色を個別に変更するメソッド（for nRF52）
  /// 近い将来サポート終了予定
  /// nodeColors: {0: LedColor.red, 1: LedColor.green, 2: LedColor.blue, ...}
  static Future<Map<String, dynamic>> setNodeColors({
    required Map<int, LedColor> nodeColors,
  }) async {
    int maxNodes = 12; // 最大ノード数
    String colorNumStrings = "0" * maxNodes;

    for (var key in nodeColors.keys) {
      if (key >= 0 && key < maxNodes) {
        String colorNum = (nodeColors[key] ?? LedColor.clear).value.toString();
        colorNumStrings = colorNumStrings.replaceRange(key, key + 1, colorNum);
      }
    }

    int colorNum = int.parse(colorNumStrings.substring(0, 4));
    int colorNum2 = int.parse(colorNumStrings.substring(4, 8));
    int colorNum3 = int.parse(colorNumStrings.substring(8, 12));

    final response = await _methodChannel.invokeMethod('setNodeColors', {
      'colorNum': colorNum,
      'colorNum2': colorNum2,
      'colorNum3': colorNum3,
    });
    bool isSuccess = response['isSuccess'] ?? false;
    String message = response['message'] ?? 'No message provided';
    return {'isSuccess': isSuccess, 'message': message};
  }
}
