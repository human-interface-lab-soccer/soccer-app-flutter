import 'package:flutter/material.dart';
// 外部Widget（別ファイルで定義したボタン部品）をインポート
import 'package:soccer_app_flutter/widgets/circle_button.dart';
import 'package:soccer_app_flutter/widgets/box_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connection Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'Connection Demo Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

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

class _MyHomePageState extends State<MyHomePage> {
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
  void handleButtonPress(ButtonPress action) {
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
        updateAction("グループ確定！！");
        break;
      case ButtonPress.checkDeviceStatus:
        updateDeviceList(["デバイスA", "デバイスB", "デバイスC"], "デバイス確認");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // アプリバーの設定
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      // メインコンテンツの設定
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('ボタンを押してね！'),
            Text(
              actionFeedback, // ボタンの押下アクションのフィードバックを表示
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            // 接続デバイスのリストを表示
            if (hasCheckedDevice)
              Expanded(
                child:
                    deviceList.isNotEmpty
                        ? ListView.builder(
                          itemCount: deviceList.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                                horizontal: 16.0,
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
      // ボタンの配置（下部中央）
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 円形ボタン：赤、青、緑、クリア
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleButton(
                key: const Key("redButton"),
                label: "赤",
                onPressed: () => handleButtonPress(ButtonPress.pressRed),
                color: Colors.red,
              ),
              const SizedBox(width: 24),
              CircleButton(
                key: const Key("blueButton"),
                label: "青",
                onPressed: () => handleButtonPress(ButtonPress.pressBlue),
                color: Colors.blue,
              ),
              const SizedBox(width: 24),
              CircleButton(
                key: const Key("greenButton"),
                label: "緑",
                onPressed: () => handleButtonPress(ButtonPress.pressGreen),
                color: Colors.green,
              ),
              const SizedBox(width: 24),
              CircleButton(
                key: const Key("clearButton"),
                label: "クリア",
                onPressed: () => handleButtonPress(ButtonPress.clearAction),
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BoxButton(
                key: const Key("connectButton"),
                label: "接続",
                onPressed: () => handleButtonPress(ButtonPress.connectDevice),
              ),
              const SizedBox(width: 24),
              BoxButton(
                key: const Key("decideGroupButton"),
                label: "グループの決定",
                onPressed:
                    () => handleButtonPress(ButtonPress.decideGroupAction),
              ),
              const SizedBox(width: 24),
              BoxButton(
                key: const Key("checkDeviceButton"),
                label: "接続確認",
                onPressed:
                    () => handleButtonPress(ButtonPress.checkDeviceStatus),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
