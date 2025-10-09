import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';

// 練習メニューデータの状態を表現するクラス
@immutable
class PracticeMenuState {
  final List<PracticeMenu> menus;
  final bool isLoading;
  final String? errorMessage;

  const PracticeMenuState({
    this.menus = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PracticeMenuState copyWith({
    List<PracticeMenu>? menus,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PracticeMenuState(
      menus: menus ?? this.menus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// 練習メニューデータを管理するNotifier
class PracticeMenuNotifier extends StateNotifier<PracticeMenuState> {
  // 順序定義を定数として定義
  static const List<String> _typeOrder = ['既存', '自由帳'];
  static const List<String> _difficultyOrder = ['初級', '中級', '上級'];
  static const _boxName = 'practice_menus';

  PracticeMenuNotifier() : super(const PracticeMenuState());

  // Hiveボックスを初期化（アプリ起動時に呼ぶ）
  static Future<void> initHive() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  // アセットファイル + Hive からデータを読み込む
  Future<void> loadMenus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

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
      final hiveMenus =
          box.values
              .map((e) => PracticeMenu.fromMap(Map<String, dynamic>.from(e)))
              .toList();

      // ③ 統合
      final menus = [...hiveMenus, ...existingMenus];

      state = state.copyWith(menus: menus, isLoading: false);

      debugPrint(
        '練習メニュー（既存${existingMenus.length}件＋自由帳${hiveMenus.length}件）を読み込みました',
      );
    } on PlatformException catch (e) {
      debugPrint('練習メニューファイルが見つかりません: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '練習メニューファイルが見つかりません',
      );
    } on FormatException catch (e) {
      debugPrint('練習メニューのJSONフォーマットエラー: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '練習メニューのJSONフォーマットエラー',
      );
    } catch (e) {
      debugPrint('練習メニューの読み込みエラー: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '練習メニューの読み込みエラー: $e',
      );
    }
  }

  // 新しいメニューをHiveに追加
  Future<void> addMenu(PracticeMenu menu) async {
    final box = Hive.box(_boxName);
    await box.put(menu.id, menu.toJson());
    state = state.copyWith(menus: [...state.menus, menu]);
  }

  // メニューを削除
  Future<void> deleteMenu(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
    state = state.copyWith(
      menus: state.menus.where((menu) => menu.id != id).toList(),
    );
  }

  // すべて削除
  Future<void> clearAll() async {
    final box = Hive.box(_boxName);
    await box.clear();
    state = state.copyWith(menus: []);
  }

  // メニューの再読み込み
  Future<void> reloadMenus() async {
    state = const PracticeMenuState();
    await loadMenus();
  }

  // カテゴリーのリストを取得
  List<String> getCategories() {
    return state.menus.map((menu) => menu.category).toSet().toList();
  }

  // タイプのリストを取得
  List<String> getTypes() {
    final types = state.menus.map((menu) => menu.type).toSet().toList();
    types.sort((a, b) => _compareByOrder(a, b, _typeOrder));
    return types;
  }

  // 難易度のリストを取得
  List<String> getDifficulties() {
    final difficulties =
        state.menus.map((menu) => menu.difficulty).toSet().toList();
    difficulties.sort((a, b) => _compareByOrder(a, b, _difficultyOrder));
    return difficulties;
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

// プロバイダーの定義
final practiceMenuProvider =
    StateNotifierProvider<PracticeMenuNotifier, PracticeMenuState>(
      (ref) => PracticeMenuNotifier(),
    );

// 使いやすさのためのプロバイダー群
final allMenusProvider = Provider<List<PracticeMenu>>((ref) {
  return ref.watch(practiceMenuProvider).menus;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(practiceMenuProvider).isLoading;
});

final errorMessageProvider = Provider<String?>((ref) {
  return ref.watch(practiceMenuProvider).errorMessage;
});

final categoriesProvider = Provider<List<String>>((ref) {
  ref.watch(practiceMenuProvider);
  return ref.read(practiceMenuProvider.notifier).getCategories();
});

final typesProvider = Provider<List<String>>((ref) {
  ref.watch(practiceMenuProvider);
  return ref.read(practiceMenuProvider.notifier).getTypes();
});

final difficultiesProvider = Provider<List<String>>((ref) {
  ref.watch(practiceMenuProvider);
  return ref.read(practiceMenuProvider.notifier).getDifficulties();
});
