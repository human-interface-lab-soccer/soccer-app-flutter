import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/features/platform_channels/mesh_network.dart';
import 'package:soccer_app_flutter/features/platform_channels/provisioning.dart';

class NetworkNodeList extends StatefulWidget {
  const NetworkNodeList({super.key});

  @override
  State<NetworkNodeList> createState() => _NetworkNodeListState();
}

class _NetworkNodeListState extends State<NetworkNodeList> {
  /// ネットワークノードのリスト
  List<Map<String, String>> _networkNodes = [];

  /// ロード中のフラグ
  bool _isLoading = true;

  /// デバッグモードのフラグ
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

  /// ネットワークノードのリストを取得するメソッド
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

  /// ノードのConfigurationを行うメソッド
  Future<void> _configureNode(final int unicastAddress) async {
    // TODO: - Configuration logic for the node
    // ignore: avoid_print
    print("Configure node with unicast address $unicastAddress");
  }

  /// ノードをリセットするメソッド
  Future<void> _resetNode(final int unicastAddress) async {
    var response = await Provisioning.resetNode(unicastAddress);
    if (!mounted) return;
    if (response['isSuccess']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Node reset successful: ${response['message']}'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Node reset failed: ${response['message']}')),
      );
    }
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
                          trailing:
                              unicastAddress == 1
                                  ? const SizedBox()
                                  : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return SimpleDialog(
                                                title: Text(
                                                  'Provisioning ${_networkNodes[index]["name"]}',
                                                ),
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16.0,
                                                        ),
                                                    child: Text(
                                                      'UUID: ${_networkNodes[index]["uuid"]}',
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      _configureNode(
                                                        unicastAddress,
                                                      );
                                                    },
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.add_to_queue,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text('Configure node'),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      _resetNode(
                                                        unicastAddress,
                                                      );
                                                    },
                                                    child: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: const Icon(Icons.edit),
                                      ),
                                    ],
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
