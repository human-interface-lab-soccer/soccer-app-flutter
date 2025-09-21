import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/features/platform_channels/mesh_network.dart';
import 'package:soccer_app_flutter/shared/models/mesh_node.dart';
import 'package:soccer_app_flutter/features/platform_channels/provisioning.dart';

class NetworkNodeDetail extends StatefulWidget {
  final MeshNode meshNode;
  const NetworkNodeDetail({super.key, required this.meshNode});

  @override
  State<NetworkNodeDetail> createState() => _NetworkNodeDetailState();
}

class _NetworkNodeDetailState extends State<NetworkNodeDetail> {
  // GenericOnOffSetの状態を保持するための変数
  bool isSelected = false;

  Future<void> _resetNode({required int unicastAddress}) async {
    // Close the dialog after resetting
    Navigator.of(context).pop();

    var response = await Provisioning.resetNode(unicastAddress);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response['isSuccess']
              ? 'Node reset successful: ${response['message']}'
              : 'Node reset failed: ${response['message']}',
        ),
      ),
    );
  }

  Future<void> _configureNode({required int unicastAddress}) async {
    Navigator.of(context).pop();
    var response = await Provisioning.configureNode(unicastAddress);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response['isSuccess']
              ? 'Node configuration successful: ${response['message']}'
              : 'Node configuration failed: ${response['message']}',
        ),
      ),
    );
  }

  Future<void> _genericOnOffSet({required bool state}) async {
    var response = await MeshNetwork.genericOnOffSet(
      unicastAddress: widget.meshNode.primaryUnicastAddress,
      state: state,
    );
    setState(() {
      isSelected = state;
    });
    if (!mounted) return;

    // 失敗した時のみにダイアログを表示
    if (!response['isSuccess']) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GenericOnOffSet failed: ${response['message']}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(widget.meshNode.name),
      contentPadding: const EdgeInsets.all(16.0),
      children: [
        Text('UUID: ${widget.meshNode.uuid}'),
        Text(
          'Primary Unicast Address: ${widget.meshNode.primaryUnicastAddress}',
        ),
        Text('Is Configured: ${widget.meshNode.isConfigured ? "Yes" : "No"}'),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed:
                  // local node の場合は削除できないようにする
                  !widget.meshNode.isLocalNode()
                      ? () {
                        _resetNode(
                          unicastAddress: widget.meshNode.primaryUnicastAddress,
                        );
                      }
                      : null,
              style: ElevatedButton.styleFrom(iconColor: Colors.red),
              child: const Icon(Icons.delete),
            ),
            const SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: () {
                _configureNode(
                  unicastAddress: widget.meshNode.primaryUnicastAddress,
                );
              },
              child: const Icon(Icons.settings),
            ),
            const SizedBox(width: 8.0),
            ToggleButtons(
              onPressed: (int index) {
                _genericOnOffSet(state: index == 0);
              },
              isSelected: [isSelected, !isSelected],
              children: [
                const Icon(Icons.lightbulb),
                const Icon(Icons.lightbulb_outlined, color: Colors.grey),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
