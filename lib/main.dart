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
        extensions: const [
          ButtonThemeExtension(
            circleButtonSize: 70.0, // 円形ボタンのデフォルトサイズ
            boxButtonMinWidth: 100.0, // 四角いボタンのデフォルト最小幅
            boxButtonHeight: 48.0, // 四角いボタンのデフォルト高さ
            buttonSpacing: 20.0, // ボタン同士の間隔
            sectionSpacing: 10.0, // ボタンとボタンの間のスペース
            contentPadding: 10.0, // コンテンツの内側余白
          ),
        ],
      ),
      home: const MyHomePage(title: 'Connection Demo Page'),
    );
  }
}

class ButtonThemeExtension extends ThemeExtension<ButtonThemeExtension> {
  final double circleButtonSize; // 円形ボタンのデフォルトサイズ
  final double boxButtonMinWidth; // 四角いボタンのデフォルト最小幅
  final double boxButtonHeight; // 四角いボタンのデフォルト高さ
  final double buttonSpacing; // ボタン同士の間隔
  final double sectionSpacing; // ボタンとボタンの間のスペース
  final double contentPadding; // コンテンツの内側余白

  const ButtonThemeExtension({
    required this.circleButtonSize,
    required this.boxButtonMinWidth,
    required this.boxButtonHeight,
    required this.buttonSpacing,
    required this.sectionSpacing,
    required this.contentPadding,
  });

  @override
  // コピー用のメソッド（一部の値だけ変更した新しいテーマを簡単に作れる）
  ButtonThemeExtension copyWith({
    double? circleButtonSize,
    double? boxButtonMinWidth,
    double? boxButtonHeight,
    double? buttonSpacing,
    double? sectionSpacing,
    double? contentPadding,
  }) {
    return ButtonThemeExtension(
      circleButtonSize: circleButtonSize ?? this.circleButtonSize,
      boxButtonMinWidth: boxButtonMinWidth ?? this.boxButtonMinWidth,
      boxButtonHeight: boxButtonHeight ?? this.boxButtonHeight,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      contentPadding: contentPadding ?? this.contentPadding,
    );
  }

  @override
  // 他のテーマと補間して滑らかな変化を作るメソッド
  // 「Aテーマ→Bテーマ」へ一瞬で切り替えるのではなく、
  // lerpで“間の値”を計算しながら、なめらかに変化させるために使われるらしい
  ButtonThemeExtension lerp(ButtonThemeExtension? other, double t) {
    if (other == null) return this;
    return ButtonThemeExtension(
      circleButtonSize:
          (circleButtonSize * (1 - t) + other.circleButtonSize * t),
      boxButtonMinWidth:
          (boxButtonMinWidth * (1 - t) + other.boxButtonMinWidth * t),
      boxButtonHeight: (boxButtonHeight * (1 - t) + other.boxButtonHeight * t),
      buttonSpacing: (buttonSpacing * (1 - t) + other.buttonSpacing * t),
      sectionSpacing: (sectionSpacing * (1 - t) + other.sectionSpacing * t),
      contentPadding: (contentPadding * (1 - t) + other.contentPadding * t),
    );
  }

  // 画面サイズに基づいてスケーリングされた値を返す
  ButtonThemeExtension scaleForScreenSize(Size screenSize) {
    // 基準サイズ（デザイン時の想定サイズ）
    const baseWidth = 400.0;
    const baseHeight = 800.0;

    // スケールファクターを計算（最小0.7倍，最大1.3倍に制限）
    final widthScale = (screenSize.width / baseWidth).clamp(0.7, 1.3);
    final heightScale = (screenSize.height / baseHeight).clamp(0.7, 1.3);
    final scale = (widthScale + heightScale) / 2;

    return ButtonThemeExtension(
      circleButtonSize: circleButtonSize * scale,
      boxButtonMinWidth: boxButtonMinWidth * scale,
      boxButtonHeight: boxButtonHeight * scale,
      buttonSpacing: buttonSpacing * scale,
      sectionSpacing: sectionSpacing * scale,
      contentPadding: contentPadding * scale,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
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

class MyHomePageState extends State<MyHomePage> {
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
        updateAction("グループ決定!!");
        break;
      case ButtonPress.checkDeviceStatus:
        updateDeviceList(
          List.generate(26, (i) => "デバイス${String.fromCharCode(65 + i)}"),
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
          circleButtonSize: 70.0, // 円形ボタンのデフォルトサイズ
          boxButtonMinWidth: 100.0, // 四角いボタンのデフォルト最小幅
          boxButtonHeight: 48.0, // 四角いボタンのデフォルト高さ
          buttonSpacing: 20.0, // ボタン同士の間隔
          sectionSpacing: 10.0, // ボタンとボタンの間のスペース
          contentPadding: 10.0, // コンテンツの内側余白
        );

    // ボタンエリアの高さを計算
    final buttonAreaHeight = calculateButtonAreaHeight(context, buttonTheme);

    // 固定コンテンツエリアの高さを計算
    final fixedContentHeight = calculateFixedContentHeight(
      context,
      buttonTheme,
    );

    return Scaffold(
      // アプリバーの設定
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
                child: SafeArea(
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
              ),
            ],
          );
        },
      ),
    );
  }
}

// ボタンエリアの高さを計算するヘルパーメソッド
double calculateButtonAreaHeight(
  BuildContext context,
  ButtonThemeExtension buttonTheme,
) {
  final mediaQuery = MediaQuery.of(context);

  // SafeAreaの下部パディング
  final bottomSafeArea = mediaQuery.padding.bottom;

  // ボタンエリアの構成要素の高さを計算
  final containerPadding = buttonTheme.contentPadding * 2; // 上下のパディング
  final circleButtonHeight = buttonTheme.circleButtonSize;
  final sectionSpacing = buttonTheme.sectionSpacing;
  final boxButtonHeight = buttonTheme.boxButtonHeight;

  return containerPadding +
      circleButtonHeight +
      sectionSpacing +
      boxButtonHeight +
      bottomSafeArea;
}

// 固定コンテンツエリアの高さを計算するヘルパーメソッド
double calculateFixedContentHeight(
  BuildContext context,
  ButtonThemeExtension buttonTheme,
) {
  // テキストの高さを推定（実際の計算はより複雑になる場合があります）
  final textStyle = Theme.of(context).textTheme.headlineMedium;
  final fontSize = textStyle?.fontSize ?? 24.0; // デフォルト値

  // 固定コンテンツの構成要素
  final firstTextHeight = 16.0 * 1.5; // 'ボタンを押してね！'の推定高さ
  final firstSpacing = buttonTheme.sectionSpacing;
  final actionFeedbackHeight = fontSize * 1.5; // 推定高さ
  final secondSpacing = buttonTheme.sectionSpacing;

  return firstTextHeight + firstSpacing + actionFeedbackHeight + secondSpacing;
}
