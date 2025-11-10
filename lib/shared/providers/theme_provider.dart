import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// テーマカラーの選択肢
enum ThemeColorOption {
  blue(Colors.blue, 'ブルー'),
  red(Colors.red, 'レッド'),
  green(Colors.green, 'グリーン'),
  purple(Colors.purple, 'パープル'),
  orange(Colors.orange, 'オレンジ'),
  teal(Colors.teal, 'ティール'),
  pink(Colors.pink, 'ピンク'),
  indigo(Colors.indigo, 'インディゴ');

  final Color color;
  final String label;

  const ThemeColorOption(this.color, this.label);
}

// テーマカラーを管理するNotifier
class ThemeColorNotifier extends StateNotifier<ThemeColorOption> {
  ThemeColorNotifier(this._box) : super(ThemeColorOption.blue) {
    _loadThemeColor();
  }

  final Box _box;
  static const _themeColorKey = 'theme_color';

  // 保存されたテーマカラーを読み込む
  Future<void> _loadThemeColor() async {
    final savedColorName = _box.get(_themeColorKey) as String?;
    if (savedColorName != null) {
      final color = ThemeColorOption.values.firstWhere(
        (option) => option.name == savedColorName,
        orElse: () => ThemeColorOption.blue,
      );
      state = color;
    }
  }

  // テーマカラーを変更して保存
  Future<void> setThemeColor(ThemeColorOption color) async {
    state = color;
    await _box.put(_themeColorKey, color.name);
  }
}

// Provider
final themeColorProvider =
    StateNotifierProvider<ThemeColorNotifier, ThemeColorOption>((ref) {
      final appSettingsBox = Hive.box('app_settings');
      return ThemeColorNotifier(appSettingsBox);
    });
