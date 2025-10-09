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
  bool onOffState = false;
  // GenericColorSetの状態を保持するための変数
  int colorIndex = 0;

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

  /// GenericOnOffノードを設定するメソッド
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

  Future<void> _setSubscription() async {
    var response = await Provisioning.setSubscription(
      unicastAddress: widget.meshNode.primaryUnicastAddress,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response['isSuccess']
              ? 'Subscription set successfully: ${response['message']}'
              : 'Failed to set subscription: ${response['message']}',
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
      onOffState = state;
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

  /// GenericColorNodeの色を変更するメソッド
  /// TODO: 実装
  Future<void> _genericColorSet({
    required int unicastAddress,
    required int color,
  }) async {
    var response = await MeshNetwork.genericColorSet(
      unicastAddress: unicastAddress,
      color: color,
    );
    setState(() {
      colorIndex = color;
    });
    if (!mounted) return;
    if (!response['isSuccess']) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GenericColorSet failed: ${response['message']}'),
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
        // Text('UUID: ${widget.meshNode.uuid}'),
        Text(
          'Primary Unicast Address: ${widget.meshNode.primaryUnicastAddress}',
        ),
        const SizedBox(height: 8.0),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
          // localNodeの場合は、リセット・設定・GenericOnOffSetのボタンを表示しない
          // widget.meshNode.isLocalNode()
          //     ? []
          //     : [
          [
            // const Divider(thickness: 1.0),
            // const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Configure Node"),
                ElevatedButton(
                  onPressed: () {
                    _configureNode(
                      unicastAddress: widget.meshNode.primaryUnicastAddress,
                    );
                  },
                  child: const Icon(Icons.settings),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Set Publication"),
                ElevatedButton(
                  onPressed: () {
                    _setSubscription();
                  },
                  child: const Icon(Icons.settings),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            const Divider(thickness: 1.0),
            Text(
              "GenericOnOff (nRF54L15)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),

            ToggleButtons(
              onPressed: (int index) {
                _genericOnOffSet(state: index == 0);
              },
              isSelected: [onOffState, !onOffState],
              children: [
                const Icon(Icons.lightbulb),
                const Icon(Icons.lightbulb_outlined, color: Colors.grey),
              ],
            ),

            const SizedBox(height: 8.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 8.0),
            Text(
              "GenericColor (nRF52x)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),

            ToggleButtons(
              onPressed: (int index) {
                // 0: none, 1: Red, 2: Green, 3: Blue
                int color = index;
                _genericColorSet(
                  unicastAddress: widget.meshNode.primaryUnicastAddress,
                  color: color,
                );
              },

              // TODO: 綺麗にする
              isSelected: [
                colorIndex == 0,
                colorIndex == 1,
                colorIndex == 2,
                colorIndex == 3,
              ],
              children: const [
                Icon(Icons.circle, color: Colors.grey),
                Icon(Icons.circle, color: Colors.red),
                Icon(Icons.circle, color: Colors.green),
                Icon(Icons.circle, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 8.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Reset Node"),
                ElevatedButton(
                  onPressed: () {
                    _resetNode(
                      unicastAddress: widget.meshNode.primaryUnicastAddress,
                    );
                  },
                  style: ElevatedButton.styleFrom(iconColor: Colors.red),
                  child: const Icon(Icons.delete),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
