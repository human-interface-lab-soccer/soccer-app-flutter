import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/features/platform_channels/general_ble_scanner.dart';
import 'package:soccer_app_flutter/shared/model/ble_device.dart';

/// 検出されたBLEデバイスのリストを表示するウィジェット
///
/// ### 主な目的:
/// - BLEデバイスのスキャンを開始し、検出されたデバイスの情報をリスト表示
///
/// ### 引数・戻り値:
/// - 特に引数はなく、ウィジェットの状態を管理するためのStatefulWidget
/// - スキャンボタンを押すことでスキャンの開始/停止が可能
///
/// ### 使用例:
/// ```dart
/// DiscoveredDeviceList();
/// ```
/// ### 注意点:
/// - スキャン中はデバイスの検出情報がリアルタイムで更新されます。
/// - スキャンを停止すると、検出されたデバイスのリストが更新されなくなります。
/// - デバイス名が"Unknown device"の場合は表示されません。
/// - スキャン中はバッテリー消費が増加する可能性があります。
/// - 実機での動作にはBluetoothの権限が必要です。
/// - スキャン中にエラーが発生した場合は、エラーメッセージがコンソールに出力されます。
class DiscoveredDeviceList extends StatefulWidget {
  const DiscoveredDeviceList({super.key});

  @override
  State<DiscoveredDeviceList> createState() => _DiscoveredDeviceListState();
}

class _DiscoveredDeviceListState extends State<DiscoveredDeviceList> {
  final GeneralBleScanner generalBleScanner = GeneralBleScanner();
  bool isScanning = false;

  Future<void> handleScanButtonPressed() async {
    if (isScanning) {
      await generalBleScanner.stopScanning();
      setState(() {
        isScanning = false;
      });
    } else {
      await generalBleScanner.startScanning();
      setState(() {
        isScanning = true;
      });
    }
  }

  Icon rssiIcon(int rssi) {
    if (rssi > -70) {
      return const Icon(Icons.network_wifi, color: Colors.green);
    } else if (rssi > -90) {
      return const Icon(Icons.network_wifi_2_bar, color: Colors.yellow);
    } else {
      return const Icon(Icons.network_wifi_1_bar, color: Colors.red);
    }
  }

  @override
  void dispose() {
    super.dispose();
    generalBleScanner.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: handleScanButtonPressed,
            child: Icon(isScanning ? Icons.stop : Icons.play_arrow),
          ),
          StreamBuilder<List<BleDevice>>(
            stream: generalBleScanner.discoveredDevicesStream,
            initialData: [],
            builder: (context, snapshot) {
              return Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children:
                      (snapshot.data ?? []).map((device) {
                        return ListTile(
                          leading: rssiIcon(device.rssi),
                          title: Text(device.name),
                          subtitle: Text(
                            'UUID: ${device.uuid}, RSSI: ${device.rssi}',
                          ),
                        );
                      }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
