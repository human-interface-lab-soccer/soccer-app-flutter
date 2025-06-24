import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/themes/button_theme_extension.dart';
import 'package:soccer_app_flutter/utils/layout_helpers.dart';
import 'package:soccer_app_flutter/widgets/circle_button.dart';
import 'package:soccer_app_flutter/widgets/box_button.dart';
import 'package:soccer_app_flutter/platform_channels/nrf_mesh_manager.dart';

// ボタンの押下アクションを定義する列挙型
enum ButtonPress {
  pressRed,
  pressBlue,
  pressGreen,
  clearAction,
  connectDevice,
  decideGroupAction,
  checkDeviceStatus,
}

// 接続ページ
class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => ConnectionPageState();
}

class ConnectionPageState extends State<ConnectionPage> {
  // ボタンの処理を表示
  String actionFeedback = "";
  // 接続デバイス名リスト
  List<String> deviceList = [];
  // デバイス確認済みフラグ
  bool hasCheckedDevice = false;

  // アクションを更新して画面に反映する関数
  void updateAction(String message) {
    setState(() {
      hasCheckedDevice = false; // デバイス確認済みフラグをリセット
      actionFeedback = message;
    });
  }

  // デバイスリストを更新して画面に反映する関数
  void updateDeviceList(List<String> devices, String message) {
    setState(() {
      hasCheckedDevice = true; // デバイス確認済みフラグをセット
      deviceList = devices;
      actionFeedback = message;
    });
  }

  // ボタンの押下アクションに応じて処理を実行する関数
  Future<void> handleButtonPress(ButtonPress action) async {
    switch (action) {
      case ButtonPress.pressRed:
        updateAction("赤だよー");
        break;
      case ButtonPress.pressBlue:
        updateAction("青だよー");
        break;
      case ButtonPress.pressGreen:
        updateAction("緑だよー");
        break;
      case ButtonPress.clearAction:
        updateAction("");
        break;
      case ButtonPress.connectDevice:
        updateAction("デバイス接続");
        break;
      case ButtonPress.decideGroupAction:
        updateAction("グループ決定!!");
        break;
      case ButtonPress.checkDeviceStatus:
        final devices = await NrfMeshManager().scanMeshNodes();
        updateDeviceList(
          devices.isNotEmpty ? devices : ["接続デバイスなし"],
          "デバイス確認",
        );
        break;
    }
  }

  List<Widget> buildCircleButtons(ButtonThemeExtension theme) {
    final data = [
      {
        "label": "赤",
        "color": Colors.red,
        "action": ButtonPress.pressRed,
        "key": "redButton",
      },
      {
        "label": "青",
        "color": Colors.blue,
        "action": ButtonPress.pressBlue,
        "key": "blueButton",
      },
      {
        "label": "緑",
        "color": Colors.green,
        "action": ButtonPress.pressGreen,
        "key": "greenButton",
      },
      {
        "label": "クリア",
        "color": Colors.grey,
        "action": ButtonPress.clearAction,
        "key": "clearButton",
      },
    ];

    final circleButtons = <Widget>[];
    for (var item in data) {
      circleButtons.add(
        CircleButton(
          key: Key(item["key"] as String),
          label: item["label"] as String,
          onPressed: () => handleButtonPress(item["action"] as ButtonPress),
          color: item["color"] as Color,
          size: theme.circleButtonSize,
        ),
      );
      circleButtons.add(SizedBox(width: theme.buttonSpacing));
    }
    circleButtons.removeLast(); // 最後のスペーサーを削除
    return circleButtons;
  }

  List<Widget> buildBoxButtons(ButtonThemeExtension theme) {
    final data = [
      {
        "label": "接続",
        "action": ButtonPress.connectDevice,
        "key": "connectButton",
      },
      {
        "label": "グループ決定",
        "action": ButtonPress.decideGroupAction,
        "key": "decideGroupButton",
      },
      {
        "label": "接続確認",
        "action": ButtonPress.checkDeviceStatus,
        "key": "checkDeviceButton",
      },
    ];

    final boxButtons = <Widget>[];
    for (var item in data) {
      boxButtons.add(
        BoxButton(
          key: Key(item["key"] as String),
          label: item["label"] as String,
          onPressed: () => handleButtonPress(item["action"] as ButtonPress),
          minWidth: theme.boxButtonMinWidth,
          height: theme.boxButtonHeight,
        ),
      );
      boxButtons.add(SizedBox(width: theme.buttonSpacing));
    }
    boxButtons.removeLast(); // 最後のスペーサーを削除
    return boxButtons;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonTheme =
        Theme.of(
          context,
        ).extension<ButtonThemeExtension>()?.scaleForScreenSize(screenSize) ??
        const ButtonThemeExtension(
          circleButtonSize: 64.0, // 円形ボタンのデフォルトサイズ
          boxButtonMinWidth: 100.0, // 四角いボタンのデフォルト最小幅
          boxButtonHeight: 48.0, // 四角いボタンのデフォルト高さ
          buttonSpacing: 20.0, // ボタン同士の間隔
          sectionSpacing: 16.0, // ボタンとボタンの間のスペース
          contentPadding: 16.0, // コンテンツの内側余白
        );

    // ボタンエリアの高さを計算
    final buttonAreaHeight = LayoutHelpers.calculateButtonAreaHeight(
      context,
      buttonTheme,
    );

    // 固定コンテンツエリアの高さを計算
    final fixedContentHeight = LayoutHelpers.calculateFixedContentHeight(
      context,
      buttonTheme,
    );

    return Scaffold(
      key: const Key('connectionPage'),
      // アプリバーの設定
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("接続"),
      ),
      // メインコンテンツの設定
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 画面の高さからボタンエリアと固定コンテンツの高さを引いた値を最大高さとして設定
          final availableHeight =
              constraints.maxHeight - buttonAreaHeight - fixedContentHeight;

          return Column(
            children: [
              // メインコンテンツエリア（スクロール可能）
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(buttonTheme.contentPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text('ボタンを押してね！', style: TextStyle(fontSize: 16)),
                      SizedBox(height: buttonTheme.sectionSpacing),
                      Text(
                        actionFeedback, // ボタンの押下アクションのフィードバックを表示
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: buttonTheme.sectionSpacing),
                      // 接続デバイスのリストを表示
                      if (hasCheckedDevice)
                        SizedBox(
                          height: availableHeight, // デバイスリストの高さ
                          child:
                              deviceList.isNotEmpty
                                  ? ListView.builder(
                                    itemCount: deviceList.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical:
                                              buttonTheme.contentPadding / 4,
                                          horizontal:
                                              buttonTheme.contentPadding,
                                        ),
                                        child: Text(
                                          deviceList[index],
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      );
                                    },
                                  )
                                  : const Center(
                                    child: Text(
                                      "接続デバイスなし",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                        ),
                    ],
                  ),
                ),
              ),
              // ボタンエリア（固定位置）
              Container(
                padding: EdgeInsets.all(buttonTheme.contentPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 円形ボタン：赤，青，緑，クリア
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: buildCircleButtons(buttonTheme),
                    ),
                    SizedBox(height: buttonTheme.sectionSpacing),
                    // 四角いボタン：接続，グループの決定，接続確認
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: buildBoxButtons(buttonTheme),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
