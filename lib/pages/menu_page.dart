import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/service/practice_menu_service.dart';
import 'package:soccer_app_flutter/pages/menu_page/practice_detail_page.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_filter_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_list_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_search_bar.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_counter_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/loading_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/error_display_widget.dart';
import 'package:soccer_app_flutter/shared/mixins/menu_filter_mixin.dart';

// データの読み込み状態を管理するenum
enum LoadingState { loading, loaded, error }

// メニューページ（検索・フィルタリング機能付き）
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with MenuFilterMixin {
  final TextEditingController _searchController = TextEditingController();
  List<PracticeMenu> _filteredMenus = [];
  LoadingState _loadingState = LoadingState.loading;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // データの読み込み処理
  Future<void> _loadData() async {
    setState(() {
      _loadingState = LoadingState.loading;
    });

    try {
      // サービス層でデータを読み込む
      await PracticeMenuService.loadMenus();

      // 成功時の処理
      _filteredMenus = PracticeMenuService.allMenus;
      setState(() {
        _loadingState = LoadingState.loaded;
      });
    } catch (e) {
      // エラー時の処理
      setState(() {
        _loadingState = LoadingState.error;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      // エラーメッセージをSnackBarで表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  // フィルタリング処理の適用
  void _applyFilters() {
    if (_loadingState != LoadingState.loaded) return;

    setState(() {
      _filteredMenus = filterMenus(
        allMenus: PracticeMenuService.allMenus,
        searchQuery: _searchController.text,
        selectedCategory: selectedCategory,
        selectedType: selectedType,
        selectedDifficulty: selectedDifficulty,
      );
    });
  }

  // カテゴリー変更時の処理
  void _onCategoryChanged(String value) {
    updateSelectedCategory(value);
    _applyFilters();
  }

  // タイプ変更時の処理
  void _onTypeChanged(String value) {
    updateSelectedType(value);
    _applyFilters();
  }

  // 難易度変更時の処理
  void _onDifficultyChanged(String value) {
    updateSelectedDifficulty(value);
    _applyFilters();
  }

  // メニュー詳細ページへの遷移
  void _navigateToDetailPage(PracticeMenu menu) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PracticeDetailPage(menu: menu)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("menuPage"),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('練習メニュー一覧'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_loadingState) {
      case LoadingState.loading:
        return const LoadingWidget(message: 'メニューを読み込み中...');

      case LoadingState.error:
        return ErrorDisplayWidget(message: _errorMessage, onRetry: _loadData);

      case LoadingState.loaded:
        return _buildContent();
    }
  }

  Widget _buildContent() {
    return Column(
      children: [
        // 検索バー
        MenuSearchBar(controller: _searchController),

        // フィルタリング機能
        MenuFilterWidget(
          selectedCategory: selectedCategory,
          selectedType: selectedType,
          selectedDifficulty: selectedDifficulty,
          onCategoryChanged: _onCategoryChanged,
          onTypeChanged: _onTypeChanged,
          onDifficultyChanged: _onDifficultyChanged,
        ),

        const SizedBox(height: 16),

        // フィルタリング後のメニュー件数表示
        MenuCounterWidget(count: _filteredMenus.length),

        const SizedBox(height: 8),

        // メニューリスト
        Expanded(
          child: MenuListWidget(
            menus: _filteredMenus,
            onMenuTap: _navigateToDetailPage,
          ),
        ),
      ],
    );
  }
}
