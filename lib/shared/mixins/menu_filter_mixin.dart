import 'package:soccer_app_flutter/shared/models/practice_menu.dart';

/// メニューフィルタリング機能を提供するMixin
mixin MenuFilterMixin {
  String _selectedCategory = 'すべて';
  String _selectedType = 'すべて';
  String _selectedDifficulty = 'すべて';

  // Getters
  String get selectedCategory => _selectedCategory;
  String get selectedType => _selectedType;
  String get selectedDifficulty => _selectedDifficulty;

  // Setters
  void updateSelectedCategory(String value) {
    _selectedCategory = value;
  }

  void updateSelectedType(String value) {
    _selectedType = value;
  }

  void updateSelectedDifficulty(String value) {
    _selectedDifficulty = value;
  }

  /// メニューのフィルタリング処理
  List<PracticeMenu> filterMenus({
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
    return selectedCategory == 'すべて' || menuCategory == selectedCategory;
  }

  /// タイプとの一致判定
  bool _matchesType(String menuType, String selectedType) {
    return selectedType == 'すべて' || menuType == selectedType;
  }

  /// 難易度との一致判定
  bool _matchesDifficulty(String menuDifficulty, String selectedDifficulty) {
    return selectedDifficulty == 'すべて' || menuDifficulty == selectedDifficulty;
  }
}
