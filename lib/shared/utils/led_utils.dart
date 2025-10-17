import 'package:flutter/material.dart';

/// LEDウィジェットのユーティリティクラス
class LedUtils {
  /// 色名をColorに変換
  static Color colorNameToColor(String colorName) {
    switch (colorName) {
      case '赤':
        return Colors.red;
      case '青':
        return Colors.blue;
      case '緑':
        return Colors.green;
      case 'クリア':
      default:
        return Colors.grey.shade200;
    }
  }

  /// 背景色に対して見やすい文字色を取得
  static Color getContrastColor(Color backgroundColor) {
    final double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// LEDが有効かどうかを判定
  static bool isActiveLed(String colorName) {
    return colorName != 'クリア';
  }
}

/// LED表示の設定クラス
class LedDisplayConfig {
  final double size;
  final double spacing;
  final double borderWidth;
  final double fontSize;
  final double shadowSpreadRadius;
  final double shadowBlurRadius;
  final double shadowAlpha;

  const LedDisplayConfig({
    required this.size,
    required this.spacing,
    required this.borderWidth,
    required this.fontSize,
    required this.shadowSpreadRadius,
    required this.shadowBlurRadius,
    required this.shadowAlpha,
  });

  /// 通常サイズの設定（練習中）
  static const LedDisplayConfig normal = LedDisplayConfig(
    size: 60,
    spacing: 12,
    borderWidth: 3,
    fontSize: 18,
    shadowSpreadRadius: 2,
    shadowBlurRadius: 10,
    shadowAlpha: 0.6,
  );

  /// 小サイズの設定（プレビュー）
  static const LedDisplayConfig small = LedDisplayConfig(
    size: 40,
    spacing: 8,
    borderWidth: 2,
    fontSize: 12,
    shadowSpreadRadius: 1,
    shadowBlurRadius: 6,
    shadowAlpha: 0.5,
  );
}
