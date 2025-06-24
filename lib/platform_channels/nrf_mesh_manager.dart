import 'dart:async';
import 'package:flutter/services.dart';

class NrfMeshManager {
  static const MethodChannel _channel = MethodChannel(
    'human.mech.saitama-u.ac.jp/nRFMesh',
  );

  Future<List<String>> scanMeshNodes() async {
    List<String> result = [""];
    try {
      var nodes = await _channel.invokeMethod('scanMeshNodes');
      result =
          (nodes as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          ["No devices found"];
    } on PlatformException catch (e) {
      throw Exception(
        'Failed to initialize NRF Mesh Manager: ${e.message ?? 'Unknown error'}',
      );
    }
    return result;
  }
}
