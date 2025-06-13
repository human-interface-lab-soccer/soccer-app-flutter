import 'package:flutter/material.dart';

// 四角いボタン用のカスタムウィジェット
class BoxButton extends StatelessWidget {
  // ボタンのラベルと押されたときのコールバック関数
  final String label;
  final VoidCallback onPressed;
  // コンストラクタ（必須パラメータ：label, onPressed）
  const BoxButton({
    super.key, //FlutterのWidget識別用のkey（省略可）
    required this.label, // ボタンに表示するテキスト
    required this.onPressed, // ボタンが押されたときのコールバック関数
  });

  // UIを構築するメソッド
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, // ボタンが押されたときの処理を設定
      child: Text(label), // ボタンに表示するテキストを設定
    );
  }
}
