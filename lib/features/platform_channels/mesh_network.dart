import 'dart:async';
import 'package:flutter/services.dart';
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
}
