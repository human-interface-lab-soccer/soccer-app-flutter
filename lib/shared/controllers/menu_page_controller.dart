import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/service/practice_menu_service.dart';
import 'package:soccer_app_flutter/shared/mixins/menu_filter_mixin.dart';

/// メニューページの状態管理を担当するコントローラー
class MenuPageController extends ChangeNotifier with MenuFilterMixin {
  final TextEditingController _searchController = TextEditingController();
  List<PracticeMenu> _filteredMenus = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  TextEditingController get searchController => _searchController;
  List<PracticeMenu> get filteredMenus => _filteredMenus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  MenuPageController() {
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// データの読み込み処理
  Future<void> loadData() async {
    _setLoading(true);
    _clearError();

    try {
      await PracticeMenuService.loadMenus();
      _filteredMenus = PracticeMenuService.allMenus;
      _setLoading(false);
    } catch (e) {
      debugPrint('データ読み込みエラー: $e');
      _setError('データの読み込みに失敗しました');
      _setLoading(false);
    }
  }

  /// フィルタリング処理の適用
  void _applyFilters() {
    _filteredMenus = filterMenus(
      allMenus: PracticeMenuService.allMenus,
      searchQuery: _searchController.text,
      selectedCategory: selectedCategory,
      selectedType: selectedType,
      selectedDifficulty: selectedDifficulty,
    );
    notifyListeners();
  }

  /// カテゴリー変更時の処理
  void onCategoryChanged(String value) {
    updateSelectedCategory(value);
    _applyFilters();
  }

  /// タイプ変更時の処理
  void onTypeChanged(String value) {
    updateSelectedType(value);
    _applyFilters();
  }

  /// 難易度変更時の処理
  void onDifficultyChanged(String value) {
    updateSelectedDifficulty(value);
    _applyFilters();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
