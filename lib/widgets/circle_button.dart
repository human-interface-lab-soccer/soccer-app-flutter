import 'package:flutter/material.dart';

// 丸型のボタン用カスタムウィジェット
class CircleButton extends StatelessWidget {
  // ボタンのデフォルトサイズ、内側余白、外枠の太さを定義
  static const double _defaultSize = 80.0; // ボタンのデフォルトサイズ
  static const double _defaultPadding = 1.0; // ボタンのデフォルト内側余白
  static const double _defaultBorderWidth = 1.0; // ボタンのデフォルト外枠の太さ

  // ボタンのラベル、押されたときのコールバック関数、ボタンの色を定義
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final double? size; // ボタンのサイズ（省略時はデフォルトサイズを使用）
  // コンストラクタ（必須パラメータ：label, onPressed, color）
  const CircleButton({
    super.key, //FlutterのWidget識別用のkey（省略可）
    required this.label, // ボタンに表示するテキスト
    required this.onPressed, // ボタンが押されたときのコールバック関数
    required this.color, // ボタンの背景色
    this.size, // ボタンのサイズ（省略時はデフォルトサイズを使用）
  });

  // UIを構築するメソッド
  @override
  Widget build(BuildContext context) {
    // サイズが指定されていない場合はデフォルトサイズを使用
    final double buttonSize = size ?? _defaultSize; // サイズが指定されていない場合はデフォルトサイズを使用
    return SizedBox(
      width: buttonSize, // ボタンの幅を設定
      height: buttonSize, // ボタンの高さを設定
      child: ElevatedButton(
        onPressed: onPressed, // ボタンが押されたときの処理を設定
        style: ElevatedButton.styleFrom(
          backgroundColor: color, // ボタンの背景色を設定
          foregroundColor: Colors.black, // ボタンの文字色を設定
          shape: const CircleBorder(
            // ボタンの形状を丸型に設定
            side: BorderSide(color: Colors.black, width: _defaultBorderWidth), // ボタンの外枠の色と太さを設定
          ),
          padding: const EdgeInsets.all(_defaultPadding), // ボタンの内側の余白を設定
        ),
        child: Text(label), // ボタンに表示するテキストを設定
      ),
    );
  }
}
