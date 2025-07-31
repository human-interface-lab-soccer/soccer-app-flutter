import 'dart:async';
import 'package:flutter/services.dart';

class MeshNetwork {
  static const MethodChannel _methodChannel = MethodChannel(
    'human.mech.saitama-u.ac.jp/meshNetworkMethodChannel',
  );

  static Future<List<Map<String, String>>> getNodeList() async {
    final response = await _methodChannel.invokeMethod('getNodeList');
    if (response is List) {
      return response.map((node) {
        return Map<String, String>.from(node);
      }).toList();
    } else {
      throw Exception('Failed to fetch node list');
    }
  }
}
