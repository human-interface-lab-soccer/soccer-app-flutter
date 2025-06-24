import 'package:flutter/material.dart';

// NotePage（自由帳ページ）
class NotePage extends StatelessWidget {
  const NotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("notePage"),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('自由帳 デモページ'),
      ),
      body: const Center(
        child: Text('このページに自由帳の内容を記載予定', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
