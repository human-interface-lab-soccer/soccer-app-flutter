import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/service/practice_menu_service.dart';
import 'package:soccer_app_flutter/pages/menu_page/practice_detail_page.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_filter_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_item_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_search_bar.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_counter_widget.dart';
import 'package:soccer_app_flutter/shared/mixins/menu_filter_mixin.dart';

// メニューページ（検索・フィルタリング機能付き）
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with MenuFilterMixin {
  final TextEditingController _searchController = TextEditingController();
  List<PracticeMenu> _filteredMenus = []; // 練習メニューのリスト
  bool _isLoading = true; // データ読み込み中フラグ

  @override
  void initState() {
    super.initState();
    _loadData();
    // 検索テキストフィールドの変更を監視してフィルタリング実行
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    // テキストコントローラーのリソースを解放
    _searchController.dispose();
    super.dispose();
  }

  // データの読み込み処理
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 練習メニューのデータを読み込む
      await PracticeMenuService.loadMenus();
      // 初期状態では全メニューを表示
      _filteredMenus = PracticeMenuService.allMenus;

      setState(() {
        _isLoading = false; // 読み込み完了
      });
    } catch (e) {
      debugPrint('データ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });

      // エラーメッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの読み込みに失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // フィルタリング処理の適用
  void _applyFilters() {
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
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('データを読み込み中...'),
                  ],
                ),
              )
              : Column(
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
                    child: ListView.builder(
                      itemCount: _filteredMenus.length,
                      itemBuilder: (context, index) {
                        final menu = _filteredMenus[index];
                        return MenuItemWidget(
                          menu: menu,
                          onTap: () => _navigateToDetailPage(menu),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
