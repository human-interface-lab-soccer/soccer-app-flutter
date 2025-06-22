import 'package:flutter/material.dart';

// メニューページ（空ページ）
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("menuPage"),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('メニュー デモページ'),
      ),
      body: const Center(
        child: Text('練習メニューの内容を記載予定', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
