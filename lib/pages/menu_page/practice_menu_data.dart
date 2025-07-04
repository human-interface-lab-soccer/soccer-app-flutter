import 'dart:convert';
import 'package:flutter/services.dart';

// 練習メニューのデータクラス
class PracticeMenu {
  final String name;
  final String category;
  final String description;
  final String type;
  final String difficulty;
  final int phaseCount;

  PracticeMenu({
    required this.name,
    required this.category,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.phaseCount,
  });

  // JSONからオブジェクトを生成するファクトリメソッド
  factory PracticeMenu.fromJson(Map<String, dynamic> json) {
    return PracticeMenu(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      difficulty: json['difficulty'] ?? '',
      phaseCount: json['phaseCount'] ?? 4,
    );
  }

  // オブジェクトをJSONに変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'type': type,
      'difficulty': difficulty,
      'phaseCount': phaseCount,
    };
  }
}

// 練習メニューのデータを管理するクラス
class PracticeMenuData {
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
      print('練習メニューを${_allMenus.length}件読み込みました');
    } catch (e) {
      print('練習メニューの読み込みエラー: $e');
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
    return _allMenus.map((menu) => menu.type).toSet().toList();
  }

  // 難易度のリストを取得
  static List<String> getDifficulties() {
    return _allMenus.map((menu) => menu.difficulty).toSet().toList();
  }

  // メニューの再読み込み（必要に応じて）
  static Future<void> reloadMenus() async {
    _isLoaded = false;
    await loadMenus();
  }
}
