import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/features/platform_channels/mesh_network.dart';
import 'package:soccer_app_flutter/features/platform_channels/provisioning.dart';

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
                        int unicastAddress = int.parse(
                          _networkNodes[index]["primaryUnicastAddress"] ?? "0",
                        );
                        return ListTile(
                          title: Text(
                            _networkNodes[index]["name"] ?? "unknown",
                          ),
                          subtitle: Text(
                            'UUID: ${_networkNodes[index]["uuid"]}, Unicast Address: ${_networkNodes[index]["primaryUnicastAddress"]}',
                          ),
                          leading: const Icon(Icons.network_check),
                          // TODO: リセットアクションの結果を表示する
                          trailing: unicastAddress == 1
                              ? const SizedBox()
                              : ElevatedButton(
                                  child: const Icon(
                                    Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      var _resp = await Provisioning.resetNode(
                                        unicastAddress,
                                      );
                                      print(_resp);
                                    },
                                  ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
