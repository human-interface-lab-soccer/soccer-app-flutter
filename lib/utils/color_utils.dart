import 'package:flutter/material.dart';

// 色に関するヘルパークラス
class ColorUtils {
  // タイプに応じた色を返すヘルパーメソッド
  static Color getTypeColor(String type) {
    switch (type) {
      case '既存':
        return Colors.blue;
      case '自由帳':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 難易度に応じた色を返すヘルパーメソッド
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '初級':
        return Colors.green;
      case '中級':
        return Colors.orange;
      case '上級':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
