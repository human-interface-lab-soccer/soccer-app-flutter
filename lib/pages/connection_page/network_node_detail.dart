import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/model/mesh_node.dart';
import 'package:soccer_app_flutter/features/platform_channels/provisioning.dart';

class NetworkNodeDetail extends StatefulWidget {
  final MeshNode meshNode;
  const NetworkNodeDetail({super.key, required this.meshNode});

  @override
  State<NetworkNodeDetail> createState() => _NetworkNodeDetailState();
}

class _NetworkNodeDetailState extends State<NetworkNodeDetail> {
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

  Future<void> _configureNode({required String uuid}) async {
    // TODO: - Configuration logic for the node
    // ignore: avoid_print
    print("Configure Node: $uuid");

    Navigator.of(context).pop();
    
    var response = await Provisioning.configureNode(uuid);
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
                _configureNode(uuid: widget.meshNode.uuid);
              },
              child: const Icon(Icons.settings),
            ),
          ],
        ),
      ],
    );
  }
}
