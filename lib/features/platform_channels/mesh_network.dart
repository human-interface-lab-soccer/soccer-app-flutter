import 'dart:async';
import 'package:flutter/services.dart';
import 'package:soccer_app_flutter/shared/models/mesh_node.dart';

class MeshNetwork {
  static const MethodChannel _methodChannel = MethodChannel(
    'human.mech.saitama-u.ac.jp/meshNetworkMethodChannel',
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
}
