import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:soccer_app_flutter/pages/main_navigation_bar.dart';
import 'package:soccer_app_flutter/shared/themes/button_theme_extension.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Hiveの初期化
  await Hive.initFlutter();

  // ✅ Box（保存場所）を開く
  await Hive.openBox('practice_menus');
  
  runApp(const ProviderScope(child: MyApp()));
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
      home: MainNavigationBar(key: mainNavigationBarKey), // keyを追加
    );
  }
}
