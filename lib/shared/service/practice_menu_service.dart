import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';

// 練習メニューのデータを管理するサービスクラス
class PracticeMenuService {
  // 順序定義を定数として定義
  static const List<String> _typeOrder = ['既存', '自由帳'];
  static const List<String> _difficultyOrder = ['初級', '中級', '上級'];
  static List<PracticeMenu> _allMenus = [];
  static bool _isLoaded = false;

  static const _boxName = 'practice_menus';

  // 新しいメニューを追加
  static Future<void> addMenu(PracticeMenu menu) async {
    final box = Hive.box(_boxName);
    await box.put(menu.id, menu.toJson());
  }

  // すべてのメニューを取得
  static List<PracticeMenu> getAllMenus() {
    final box = Hive.box(_boxName);
    return box.values
        .map((e) => PracticeMenu.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // メニューを削除
  static Future<void> deleteMenu(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
  }

  // すべて削除
  static Future<void> clearAll() async {
    final box = Hive.box(_boxName);
    await box.clear();
  }

  // アセットファイルからデータを読み込む
  static Future<void> loadMenus() async {
    if (_isLoaded) return;

    try {
      // ① アセットファイルからJSONデータを読み込み
      final String jsonString = await rootBundle.loadString(
        'assets/data/practice_menus.json',
      );

      // JSONをパース
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // メニューリストを作成
      final List<dynamic> menuList = jsonData['menus'] ?? [];
      final existingMenus =
          menuList.map((menuData) => PracticeMenu.fromMap(menuData)).toList();

      // ② Hiveからユーザー作成メニュー（自由帳）を読み込み
      final box = Hive.box(_boxName);
      final hiveMenus = box.values
          .map((e) => PracticeMenu.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // ③ 統合
      _allMenus = [...hiveMenus, ...existingMenus];

      _isLoaded = true; // 読み込み完了フラグを設定
      debugPrint('練習メニュー（既存${existingMenus.length}件＋自由帳${hiveMenus.length}件）を読み込みました');
    } on PlatformException catch (e) {
      // アセットファイルが見つからない場合
      debugPrint('練習メニューファイルが見つかりません: $e');
      _allMenus = [];
      _isLoaded = false; // 読み込み失敗フラグを設定
      throw Exception('練習メニューファイルが見つかりません');
    } on FormatException catch (e) {
      // JSONのフォーマットが不正な場合
      debugPrint('練習メニューのJSONフォーマットエラー: $e');
      _allMenus = [];
      _isLoaded = false; // 読み込み失敗フラグを設定
      throw Exception('練習メニューのJSONフォーマットエラー');
    } catch (e) {
      // その他の予期しないエラー
      debugPrint('練習メニューの読み込みエラー: $e');
      _allMenus = [];
      _isLoaded = false; // 読み込み失敗フラグを設定
      throw Exception('練習メニューの読み込みエラー: $e');
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
    types.sort((a, b) => _compareByOrder(a, b, _typeOrder));
    return types;
  }

  // 難易度のリストを取得
  static List<String> getDifficulties() {
    final difficulties =
        _allMenus.map((menu) => menu.difficulty).toSet().toList();
    difficulties.sort((a, b) => _compareByOrder(a, b, _difficultyOrder));
    return difficulties;
  }

  // メニューの再読み込み（必要に応じて）
  static Future<void> reloadMenus() async {
    _isLoaded = false;
    await loadMenus();
  }

  // 共通のソート関数
  static int _compareByOrder(String a, String b, List<String> order) {
    final indexA = order.indexOf(a);
    final indexB = order.indexOf(b);

    // 定義されていない項目は最後に配置
    if (indexA == -1 && indexB == -1) return 0;
    if (indexA == -1) return 1;
    if (indexB == -1) return -1;

    return indexA.compareTo(indexB);
  }
}
