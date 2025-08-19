import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/pages/menu_page/practice_detail_page.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_filter_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_list_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_search_bar_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_counter_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/loading_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/error_display_widget.dart';
import 'package:soccer_app_flutter/shared/providers/practice_menu_provider.dart';
import 'package:soccer_app_flutter/shared/providers/menu_filter_provider.dart';

// メニューページ（Riverpod版）
class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // ページ初期化時にデータを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(practiceMenuProvider.notifier).loadMenus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref
        .read(menuFilterProvider.notifier)
        .updateSearchQuery(_searchController.text);
  }

  // カテゴリー変更時の処理
  void _onCategoryChanged(String value) {
    ref.read(menuFilterProvider.notifier).updateCategory(value);
  }

  // タイプ変更時の処理
  void _onTypeChanged(String value) {
    ref.read(menuFilterProvider.notifier).updateType(value);
  }

  // 難易度変更時の処理
  void _onDifficultyChanged(String value) {
    ref.read(menuFilterProvider.notifier).updateDifficulty(value);
  }

  // メニュー詳細ページへの遷移
  void _navigateToDetailPage(PracticeMenu menu) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PracticeDetailPage(menu: menu)),
    );
  }

  // データの再読み込み処理
  void _reloadData() {
    ref.read(practiceMenuProvider.notifier).reloadMenus();
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
    final isLoading = ref.watch(isLoadingProvider);
    final errorMessage = ref.watch(errorMessageProvider);

    if (isLoading) {
      return const LoadingWidget(message: 'メニューを読み込み中...');
    }

    if (errorMessage != null) {
      return ErrorDisplayWidget(message: errorMessage, onRetry: _reloadData);
    }

    return _buildContent();
  }

  Widget _buildContent() {
    final filteredMenus = ref.watch(filteredMenusProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedType = ref.watch(selectedTypeProvider);
    final selectedDifficulty = ref.watch(selectedDifficultyProvider);

    return Column(
      children: [
        // 検索バー
        MenuSearchBarWidget(controller: _searchController),

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
        MenuCounterWidget(count: filteredMenus.length),

        const SizedBox(height: 8),

        // メニューリスト
        Expanded(
          child: MenuListWidget(
            menus: filteredMenus,
            onMenuTap: _navigateToDetailPage,
          ),
        ),
      ],
    );
  }
}

// エラー発生時にSnackBarを表示するためのConsumerWidget
class MenuPageWithErrorHandling extends ConsumerWidget {
  const MenuPageWithErrorHandling({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // エラーメッセージの変更を監視
    ref.listen<String?>(errorMessageProvider, (previous, next) {
      if (next != null && previous != next) {
        // エラーが発生した場合，SnackBarで表示
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: '再試行',
                textColor: Colors.white,
                onPressed: () {
                  ref.read(practiceMenuProvider.notifier).reloadMenus();
                },
              ),
            ),
          );
        });
      }
    });

    return const MenuPage();
  }
}
