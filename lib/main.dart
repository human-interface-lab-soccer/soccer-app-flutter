import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_app_flutter/pages/main_navigation_bar.dart';
import 'package:soccer_app_flutter/shared/themes/button_theme_extension.dart';

void main() {
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
            circleButtonSize: 64.0,
            boxButtonMinWidth: 100.0,
            boxButtonHeight: 48.0,
            buttonSpacing: 20.0,
            sectionSpacing: 16.0,
            contentPadding: 16.0,
          ),
        ],
      ),
      home: MainNavigationBar(key: mainNavigationBarKey), // keyを追加
    );
  }
}
