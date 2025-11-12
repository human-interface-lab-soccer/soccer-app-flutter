import 'package:flutter/material.dart';

/// LED色の列挙型
enum LedColor {
  clear("クリア", 0, Colors.grey),
  red("赤", 1, Colors.red),
  green("緑", 2, Colors.green),
  blue("青", 3, Colors.blue),
  purple("紫", 4, Colors.purple),
  yellow("黄", 5, Colors.yellow),
  cyan("シアン", 6, Colors.cyan),
  white("白", 7, Colors.white);

  final String label;
  final int value;
  final Color baseColor;

  static const int _minimumValue = 0;

  const LedColor(this.label, this.value, this.baseColor);

  /// 値からLedColorを取得
  static LedColor fromValue(int value) {
    if (value < _minimumValue || value >= LedColor.values.length) {
      throw Exception('Invalid LedColor value: $value');
    }
    return LedColor.values[value];
  }

  /// ラベルからLedColorを取得
  static LedColor fromLabel(String label) {
    for (var color in LedColor.values) {
      if (color.label == label) {
        return color;
      }
    }
    throw Exception('Invalid LedColor label: $label');
  }

  /// 表示用のColorを取得（クリアの場合はグレー）
  Color get displayColor {
    return this == LedColor.clear ? Colors.grey.shade200 : baseColor;
  }

  /// LEDが有効かどうか
  bool get isActive {
    return this != LedColor.clear;
  }

  /// この色に対して見やすい文字色を取得
  Color getContrastColor() {
    final double luminance = displayColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
