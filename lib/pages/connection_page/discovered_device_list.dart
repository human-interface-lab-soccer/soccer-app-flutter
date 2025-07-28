import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/features/platform_channels/general_ble_scanner.dart';
import 'package:soccer_app_flutter/features/platform_channels/provisioning.dart';
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
  final bool _isDebugMode = const bool.fromEnvironment(
    'DEBUG',
    defaultValue: false,
  );
  final List<BleDevice> _testDevices = [
    BleDevice(
      name: 'Test Device 1',
      uuid: 'test-device-1-uuid',
      rssi: -65,
      lastSeen: DateTime.now(),
    ),
    BleDevice(
      name: 'Test Device 2',
      uuid: 'test-device-2-uuid',
      rssi: -75,
      lastSeen: DateTime.now(),
    ),
    BleDevice(
      name: 'Test Device 3',
      uuid: 'test-device-3-uuid',
      rssi: -95,
      lastSeen: DateTime.now(),
    ),
  ];

  final GeneralBleScanner generalBleScanner = GeneralBleScanner();
  final Provisioning _provisioning = Provisioning();
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

  Future<void> handleStartProvisioning(String uuid) async {
    Map<String, dynamic> response = await _provisioning.startProvisioning(uuid);
    if (!mounted) return;

    bool isSuccess = response['isSuccess'] ?? false;
    String message = response['message'] ?? 'No message provided';

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Provisioning successfully started")),
      );
      // streamを購読して、プロビジョニングの進捗を受け取る
      _provisioning.provisioningStream.listen(
        (data) {
          if (!mounted) return;
          SnackBar snackBar = SnackBar(
            content: Text(
              '${data['status'] ?? 'Unknown'}: ${data["message"] ?? ""}',
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        },
        onError: (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Provisioning error: $error')));
        },
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("error: $message")));
    }
    // close the dialog after provisioning
    Navigator.of(context).pop();
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
            initialData: _isDebugMode ? _testDevices : [],
            builder: (context, snapshot) {
              return Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children:
                      (snapshot.data ?? (_isDebugMode ? _testDevices : [])).map(
                        (device) {
                          return ListTile(
                            leading: rssiIcon(device.rssi),
                            title: Text(device.name),
                            subtitle: Text(
                              'UUID: ${device.uuid}, RSSI: ${device.rssi}',
                            ),
                            onTap: () async {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return SimpleDialog(
                                    title: Text('Provisioning ${device.name}'),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          'UUID: ${device.uuid}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: ElevatedButton(
                                          onPressed:
                                              () => handleStartProvisioning(
                                                device.uuid,
                                              ),
                                          child: const Text(
                                            'Start Provisioning',
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
