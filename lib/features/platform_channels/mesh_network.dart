import 'dart:async';
import 'package:flutter/services.dart';

class MeshNetwork {
  static const MethodChannel _methodChannel = MethodChannel(
    'human.mech.saitama-u.ac.jp/meshNetworkMethodChannel',
  );

  static Future<void> getNodeList() async {
    final responce = await _methodChannel.invokeMethod('getNodeList');
    print("Node List Fetched: ");
    print(responce);
  }
}
