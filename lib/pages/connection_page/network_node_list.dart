import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/features/platform_channels/mesh_network.dart';

class NetworkNodeList extends StatefulWidget {
  const NetworkNodeList({super.key});

  @override
  State<NetworkNodeList> createState() => _NetworkNodeListState();
}

class _NetworkNodeListState extends State<NetworkNodeList> {
  List<Map<String, String>> _networkNodes = [];
  bool _isLoading = true;
  final bool _isDebugMode = const bool.fromEnvironment(
    'DEBUG',
    defaultValue: false,
  );

  @override
  void initState() {
    super.initState();
    // Fetch the node list when the widget is initialized
    _fetchNodeList();
  }

  Future<void> _fetchNodeList() async {
    var networkNodes = await MeshNetwork.getNodeList();
    if (_isDebugMode) {
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate loading delay
    }
    setState(() {
      _networkNodes = networkNodes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _networkNodes.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            _networkNodes[index]["name"] ?? "unknown",
                          ),
                          subtitle: Text(
                            'UUID: ${_networkNodes[index]["uuid"]}, Unicast Address: ${_networkNodes[index]["primaryUnicastAddress"]}',
                          ),
                          leading: const Icon(Icons.network_check),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap:
                              () => {
                                // Handle node tap action here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Tapped on ${_networkNodes[index]}',
                                    ),
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
