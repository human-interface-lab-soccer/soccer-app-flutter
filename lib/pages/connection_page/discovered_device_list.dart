import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/features/platform_channels/general_ble_scanner.dart';
import 'package:soccer_app_flutter/shared/model/ble_device.dart';

class DiscoveredDeviceList extends StatefulWidget {
  const DiscoveredDeviceList({super.key});

  @override
  State<DiscoveredDeviceList> createState() => _DiscoveredDeviceListState();
}

class _DiscoveredDeviceListState extends State<DiscoveredDeviceList> {
  final GeneralBleScanner generalBleScanner = GeneralBleScanner();
  bool isScanning = true;

  void handleScanButtonPressed() {
    if (isScanning) {
      setState(() {
        isScanning = false;
      });
      generalBleScanner.stop();
    } else {
      generalBleScanner.restart();
      setState(() {
        isScanning = true;
      });
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
            child: Icon(
              isScanning ? Icons.stop : Icons.play_arrow,
            ),
          ),
          StreamBuilder<List<BleDevice>>(
            stream: generalBleScanner.discoveredDevicesStream,
            initialData: [],
            builder: (context, snapshot) {
              return Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children:
                      generalBleScanner.discoveredDevices.map((device) {
                        if (device.name == "Unknown device") {
                          // デバイス名が"Unknown Device"の場合は表示しない
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          title: Text(device.name),
                          subtitle: Text(
                            'UUID: ${device.uuid}, RSSI: ${device.rssi}, Last Seen: ${device.lastSeen}',  
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
