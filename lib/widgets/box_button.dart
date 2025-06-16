import 'package:flutter/material.dart';

// 四角いボタン用のカスタムウィジェット
class BoxButton extends StatelessWidget {
  // ボタンのデフォルトサイズ、内側余白、外枠の太さを定義
  static const double _defaultPadding = 1.0; // ボタンのデフォルト内側余白
  static const double _defaultMinWidth = 100.0; // ボタンのデフォルト最小幅
  static const double _defaultHeight = 48.0; // ボタンのデフォルト最小高さ
  // ボタンのラベルと押されたときのコールバック関数
  final String label;
  final VoidCallback onPressed;
  final double? minWidth; // ボタンの最小幅（省略時はデフォルト最小幅を使用）
  final double? height; // ボタンの高さ（省略時はデフォルト高さを使用）

  // コンストラクタ（必須パラメータ：label, onPressed）
  const BoxButton({
    super.key, //FlutterのWidget識別用のkey（省略可）
    required this.label, // ボタンに表示するテキスト
    required this.onPressed, // ボタンが押されたときのコールバック関数
    this.minWidth, // ボタンの最小幅（省略時はデフォルト最小幅を使用）
    this.height, // ボタンの高さ（省略時はデフォルト高さを使用）
  });

  // UIを構築するメソッド
  @override
  Widget build(BuildContext context) {
    final double buttonWidth =
        minWidth ?? _defaultMinWidth; // 最小幅を設定（省略時はデフォルト最小幅を使用）
    final double buttonHeight =
        height ?? _defaultHeight; // 高さを設定（省略時はデフォルト高さを使用）

    final double scaleFactor =
        (buttonWidth / _defaultMinWidth + buttonHeight / _defaultHeight) /
        2; // サイズスケーリングの計算
    final double scaledPadding = _defaultPadding * scaleFactor; // 内側余白のスケーリング
    final double scaledBorderWidth =
        _defaultPadding * scaleFactor; // 外枠の太さのスケーリング
    final double fontSize = 14.0 * scaleFactor; // 基準フォントサイズ14.0のスケーリング

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight, // ボタンの高さを設定（省略時はデフォルト高さを使用）
      child: ElevatedButton(
        onPressed: onPressed, // ボタンが押されたときの処理を設定
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: scaledPadding,
            vertical: scaledPadding / 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              8.0 * scaleFactor,
            ), // ボタンの角を丸くする
            side: BorderSide(
              color: Colors.black,
              width: scaledBorderWidth,
            ), // ボタンの外枠の色と太さを設定
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: fontSize), // ボタンのテキストサイズを設定
        ),
      ),
    );
  }
}
