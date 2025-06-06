import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conection Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'conection Demo Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ボタンの処理を表示
  String buttonOutput = "";
  // デバイス名リスト
  List<String> deviceList = [];
  bool hasCheckedDevice = false;

  // 赤を表示
  void showRed() {
    setState(() {
      hasCheckedDevice = false;
      buttonOutput = "赤だよー";
    });
  }

  // 青を表示
  void showBlue() {
    setState(() {
      hasCheckedDevice = false;
      buttonOutput = "青だよー";
    });
  }

  // 緑を表示
  void showGreen() {
    setState(() {
      hasCheckedDevice = false;
      buttonOutput = "緑だよー";
    });
  }

  // 色をリセット
  void clearColor() {
    setState(() {
      hasCheckedDevice = false;
      buttonOutput = "";
    });
  }

  // 接続ボタン
  void connectDevice() {
    setState(() {
      hasCheckedDevice = false;
      buttonOutput = "デバイス接続";
    });
  }

  // グループ作成
  void decideGroup() {
    setState(() {
      hasCheckedDevice = false;
      buttonOutput = "グループ確定！！";
    });
  }

  // 接続デバイス確認ボタン
  void checkDevice() {
    setState(() {
      hasCheckedDevice = true;
      deviceList = ["デバイスA", "デバイスB", "デバイスC"];
      buttonOutput = "デバイス確認";
    });
  }

  // 丸ボタンの作成
  Widget _buildCircleButton(String label, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed, //押された時の処理
      style: ElevatedButton.styleFrom(
        backgroundColor: color, // 背景色を指定
        foregroundColor: Colors.white, //文字色
        shape: const CircleBorder(
          //丸型
          side: BorderSide(color: Colors.black, width: 1),
        ),
        padding: const EdgeInsets.all(36),
      ),
      child: Text(label),
    );
  }

  Widget _buildBoxButton(String label, VoidCallback onPressed) {
    return ElevatedButton(onPressed: onPressed, child: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('テスト10'),
            Text(
              '$buttonOutput',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            if(hasCheckedDevice)
              Expanded(
                child: deviceList.isNotEmpty
                  ? ListView.builder(
                    itemCount: deviceList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCircleButton("", showRed, Colors.red),
              const SizedBox(width: 24),
              _buildCircleButton("", showBlue, Colors.blue),
              const SizedBox(width: 24),
              _buildCircleButton("", showGreen, Colors.green),
              const SizedBox(width: 24),
              _buildCircleButton("", clearColor, Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBoxButton("接続", connectDevice),
              const SizedBox(width: 24),
              _buildBoxButton("グループの決定", decideGroup),
              const SizedBox(width: 24),
              _buildBoxButton("接続確認", checkDevice),
            ],
          ),
        ],
      ),
    );
  }
}
