import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/pages/menu_page.dart';
import 'package:soccer_app_flutter/pages/connection_page.dart';
import 'package:soccer_app_flutter/pages/note_page.dart';
import 'package:soccer_app_flutter/theme/button_theme_extension.dart';

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
            circleButtonSize: 64.0, // 円形ボタンのデフォルトサイズ
            boxButtonMinWidth: 100.0, // 四角いボタンのデフォルト最小幅
            boxButtonHeight: 48.0, // 四角いボタンのデフォルト高さ
            buttonSpacing: 20.0, // ボタン同士の間隔
            sectionSpacing: 16.0, // ボタンとボタンの間のスペース
            contentPadding: 16.0, // コンテンツの内側余白
          ),
        ],
      ),
      home: const MainNavigationPage(title: 'Connection Demo Page'),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key, required this.title});
  final String title;

  @override
  State<MainNavigationPage> createState() => MainNavigationPageState();
}

class MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 1; // デフォルは接続画面（インデックス1）

  // 各画面のリスト
  final List<Widget> _pages = [
    const MenuPage(),
    const ConnectionPage(),
    const NotePage(),
  ];

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 選択されたインデックスを更新
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // 選択されたページを表示
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'メニュー'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth_connected),
            label: '接続',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '自由帳'),
        ],
        currentIndex: _selectedIndex, // 現在のインデックスを設定
        onTap: onItemTapped, // アイテムがタップされたときの処理
      ),
    );
  }
}
