import 'package:flutter/material.dart';

class NetworkNodeList extends StatelessWidget {
  const NetworkNodeList({super.key});

  // sample data for network nodes
  final networkNodes = const <Map<String, String>>[
    {'deviceName': "device1", "uuid": "uuid1-xxx", "unicastAddress": "0x0002"},
    {"deviceName": "device2", "uuid": "uuid2-xxx", "unicastAddress": "0x0003"},
    {"deviceName": "device3", "uuid": "uuid3-xxx", "unicastAddress": "0x0004"},
    {"deviceName": "device4", "uuid": "uuid4-xxx", "unicastAddress": "0x0005"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: networkNodes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(networkNodes[index]["deviceName"] ?? "unknown"),
                  subtitle: Text(
                    'UUID: ${networkNodes[index]["uuid"]}, Unicast Address: ${networkNodes[index]["unicastAddress"]}',
                  ),
                  leading: Icon(Icons.network_check),
                  trailing: Icon(Icons.arrow_forward),
                  onTap:
                      () => {
                        // Handle node tap action here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tapped on ${networkNodes[index]}'),
                          ),
                        ),
                      },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
