import 'package:flutter/material.dart';

/// メニュー検索バーウィジェット
class MenuSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const MenuSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: '練習メニューを検索',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
