import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/providers/practice_menu_provider.dart';

/// デフォルトフィルタ値
const defaultFilterValue = 'すべて';

/// フィルタ状態を表現するクラス
@immutable
class MenuFilterState {
  final String selectedCategory;
  final String selectedType;
  final String selectedDifficulty;
  final String searchQuery;

  const MenuFilterState({
    this.selectedCategory = defaultFilterValue,
    this.selectedType = defaultFilterValue,
    this.selectedDifficulty = defaultFilterValue,
    this.searchQuery = '',
  });

  MenuFilterState copyWith({
    String? selectedCategory,
    String? selectedType,
    String? selectedDifficulty,
    String? searchQuery,
  }) {
    return MenuFilterState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedType: selectedType ?? this.selectedType,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// メニューフィルタを管理するNotifier
class MenuFilterNotifier extends StateNotifier<MenuFilterState> {
  MenuFilterNotifier() : super(const MenuFilterState());

  void updateCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void updateType(String type) {
    state = state.copyWith(selectedType: type);
  }

  void updateDifficulty(String difficulty) {
    state = state.copyWith(selectedDifficulty: difficulty);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void resetFilters() {
    state = const MenuFilterState();
  }
}

/// フィルタプロバイダー
final menuFilterProvider =
    StateNotifierProvider<MenuFilterNotifier, MenuFilterState>(
      (ref) => MenuFilterNotifier(),
    );

/// フィルタリングされたメニューリストを提供するプロバイダー
final filteredMenusProvider = Provider<List<PracticeMenu>>((ref) {
  final allMenus = ref.watch(allMenusProvider);
  final filterState = ref.watch(menuFilterProvider);

  return _filterMenus(
    allMenus: allMenus,
    searchQuery: filterState.searchQuery,
    selectedCategory: filterState.selectedCategory,
    selectedType: filterState.selectedType,
    selectedDifficulty: filterState.selectedDifficulty,
  );
});

/// メニューのフィルタリング処理（静的関数として抽出）
List<PracticeMenu> _filterMenus({
  required List<PracticeMenu> allMenus,
  required String searchQuery,
  required String selectedCategory,
  required String selectedType,
  required String selectedDifficulty,
}) {
  final query = searchQuery.toLowerCase();

  return allMenus.where((menu) {
    final nameMatch = _matchesSearchQuery(menu.name, query);
    final categoryMatch = _matchesCategory(menu.category, selectedCategory);
    final typeMatch = _matchesType(menu.type, selectedType);
    final difficultyMatch = _matchesDifficulty(
      menu.difficulty,
      selectedDifficulty,
    );

    return nameMatch && categoryMatch && typeMatch && difficultyMatch;
  }).toList();
}

/// 検索クエリとの一致判定
bool _matchesSearchQuery(String menuName, String query) {
  return query.isEmpty || menuName.toLowerCase().contains(query);
}

/// カテゴリーとの一致判定
bool _matchesCategory(String menuCategory, String selectedCategory) {
  return selectedCategory == defaultFilterValue ||
      menuCategory == selectedCategory;
}

/// タイプとの一致判定
bool _matchesType(String menuType, String selectedType) {
  return selectedType == defaultFilterValue || menuType == selectedType;
}

/// 難易度との一致判定
bool _matchesDifficulty(String menuDifficulty, String selectedDifficulty) {
  return selectedDifficulty == defaultFilterValue ||
      menuDifficulty == selectedDifficulty;
}

// 個別のフィルタ値を取得するプロバイダー群
final selectedCategoryProvider = Provider<String>((ref) {
  return ref.watch(menuFilterProvider).selectedCategory;
});

final selectedTypeProvider = Provider<String>((ref) {
  return ref.watch(menuFilterProvider).selectedType;
});

final selectedDifficultyProvider = Provider<String>((ref) {
  return ref.watch(menuFilterProvider).selectedDifficulty;
});

final searchQueryProvider = Provider<String>((ref) {
  return ref.watch(menuFilterProvider).searchQuery;
});
