import 'package:flutter/material.dart';

/// メニューカウント表示ウィジェット
class MenuCounterWidget extends StatelessWidget {
  final int count;

  const MenuCounterWidget({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count件の練習メニュー',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
