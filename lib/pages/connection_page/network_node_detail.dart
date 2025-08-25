import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/model/mesh_node.dart';

class NetworkNodeDetail extends StatefulWidget {
  final MeshNode meshNode;
  const NetworkNodeDetail({super.key, required this.meshNode});

  @override
  State<NetworkNodeDetail> createState() => _NetworkNodeDetailState();
}

class _NetworkNodeDetailState extends State<NetworkNodeDetail> {

  void _resetNode({required String uuid}) {
    // TODO: - Reset logic for the node
    // ignore: avoid_print
    print("Reset Node: $uuid");
  }

  void _configureNode({required String uuid}) {
    // TODO: - Configuration logic for the node
    // ignore: avoid_print
    print("Configure Node: $uuid");
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(widget.meshNode.name),
      contentPadding: const EdgeInsets.all(16.0),
      children: [
        Text('UUID: ${widget.meshNode.uuid}'),
        Text('Primary Unicast Address: ${widget.meshNode.primaryUnicastAddress}'),
        Text('Is Configured: ${widget.meshNode.isConfigured ? "Yes" : "No"}'),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _resetNode(uuid: widget.meshNode.uuid);
              },
              style: ElevatedButton.styleFrom(
                iconColor: Colors.red,
              ),
              child: const Icon(Icons.delete),
            ),
            const SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: () {
                _configureNode(uuid: widget.meshNode.uuid);
              },
              child: const Icon(Icons.settings),
            )
          ],
        )
      ],
    );
  }
}
