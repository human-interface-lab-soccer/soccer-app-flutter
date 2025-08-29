import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/features/platform_channels/mesh_network.dart';
// import 'package:soccer_app_flutter/features/platform_channels/provisioning.dart';
import 'package:soccer_app_flutter/shared/model/mesh_node.dart';
import 'package:soccer_app_flutter/pages/connection_page/network_node_detail.dart';

class NetworkNodeList extends StatefulWidget {
  const NetworkNodeList({super.key});

  @override
  State<NetworkNodeList> createState() => _NetworkNodeListState();
}

class _NetworkNodeListState extends State<NetworkNodeList> {
  /// MeshNetworkから取得したノードを格納するリスト
  List<MeshNode> _meshNodes = [];

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
    _meshNodes = await MeshNetwork.getNodeList();
    if (_isDebugMode) {
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate loading delay
    }
    setState(() {
      // _networkNodes = networkNodes;
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
                      itemCount: _meshNodes.length,
                      itemBuilder: (context, index) {
                        final node = _meshNodes[index];
                        return ListTile(
                          title: Text(node.name),
                          subtitle: Text(
                            'UUID: ${node.uuid}, Unicast Address: ${node.primaryUnicastAddress}',
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) =>
                                      NetworkNodeDetail(meshNode: node),
                            );
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
