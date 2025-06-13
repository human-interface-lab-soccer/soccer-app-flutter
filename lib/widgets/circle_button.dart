import 'package:flutter/material.dart';

// 丸型のボタン用カスタムウィジェット
class CircleButton extends StatelessWidget {
  // ボタンのラベル、押されたときのコールバック関数、ボタンの色を定義
  final String label;
  final VoidCallback onPressed;
  final Color color;
  // コンストラクタ（必須パラメータ：label, onPressed, color）
  const CircleButton({
    super.key, //FlutterのWidget識別用のkey（省略可）
    required this.label, // ボタンに表示するテキスト
    required this.onPressed, // ボタンが押されたときのコールバック関数
    required this.color, // ボタンの背景色
  });

  // UIを構築するメソッド
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, // ボタンが押されたときの処理を設定
      style: ElevatedButton.styleFrom(
        backgroundColor: color, // ボタンの背景色を設定
        foregroundColor: Colors.black, // ボタンの文字色を設定
        shape: const CircleBorder(
          // ボタンの形状を丸型に設定
          side: BorderSide(color: Colors.black, width: 1), // ボタンの外枠の色と太さを設定
        ),
        padding: const EdgeInsets.all(66), // ボタンの内側の余白を設定
      ),
      child: Text(label), // ボタンに表示するテキストを設定
    );
  }
}
