import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/pages/main_navigation_page.dart';
import 'package:soccer_app_flutter/themes/button_theme_extension.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soccer App Flutter Demo',
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
      home: const MainNavigationPage(),
    );
  }
}
