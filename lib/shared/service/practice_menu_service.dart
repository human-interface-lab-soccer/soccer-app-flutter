import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';

// 練習メニューのデータを管理するサービスクラス
class PracticeMenuService {
  static List<PracticeMenu> _allMenus = [];
  static bool _isLoaded = false;

  // アセットファイルからデータを読み込む
  static Future<void> loadMenus() async {
    if (_isLoaded) return;

    try {
      // アセットファイルからJSONデータを読み込み
      final String jsonString = await rootBundle.loadString(
        'assets/data/practice_menus.json',
      );

      // JSONをパース
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // メニューリストを作成
      final List<dynamic> menuList = jsonData['menus'] ?? [];
      _allMenus =
          menuList.map((menuData) => PracticeMenu.fromJson(menuData)).toList();

      _isLoaded = true;
      debugPrint('練習メニューを${_allMenus.length}件読み込みました');
    } catch (e) {
      debugPrint('練習メニューの読み込みエラー: $e');
      // エラーが発生した場合は空のリストを設定
      _allMenus = [];
      _isLoaded = true;
    }
  }

  // 全メニューを取得
  static List<PracticeMenu> get allMenus => _allMenus;

  // カテゴリーのリストを取得
  static List<String> getCategories() {
    return _allMenus.map((menu) => menu.category).toSet().toList();
  }

  // タイプのリストを取得
  static List<String> getTypes() {
    final types = _allMenus.map((menu) => menu.type).toSet().toList();
    types.sort((a, b) {
      const order = ['既存', '自由帳'];
      return order.indexOf(a).compareTo(order.indexOf(b));
    });
    return types;
  }

  // 難易度のリストを取得
  static List<String> getDifficulties() {
    final difficulties =
        _allMenus.map((menu) => menu.difficulty).toSet().toList();
    difficulties.sort((a, b) {
      const order = ['初級', '中級', '上級'];
      return order.indexOf(a).compareTo(order.indexOf(b));
    });
    return difficulties;
  }

  // メニューの再読み込み（必要に応じて）
  static Future<void> reloadMenus() async {
    _isLoaded = false;
    await loadMenus();
  }
}
