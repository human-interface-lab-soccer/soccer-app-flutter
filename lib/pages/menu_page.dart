import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/service/practice_menu_service.dart';
import 'package:soccer_app_flutter/pages/menu_page/practice_detail_page.dart';
import 'package:soccer_app_flutter/shared/utils/color_helper.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_filter_widget.dart';

// メニューページ（検索・フィルタリング機能付き）
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'すべて';
  String _selectedType = 'すべて';
  String _selectedDifficulty = 'すべて';
  List<PracticeMenu> _filteredMenus = []; // 練習メニューのリスト
  bool _isLoading = true; // データ読み込み中フラグ

  @override
  void initState() {
    super.initState();
    _loadData();
    // 検索テキストフィールドの変更を監視してフィルタリング実行
    _searchController.addListener(_filterMenus);
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

  void _filterMenus() {
    // 検索テキストを小文字に変換（大文字小文字を区別しない検索のため）
    final query = _searchController.text.toLowerCase();
    setState(() {
      // 全メニューから条件に合致するものだけを抽出
      _filteredMenus =
          PracticeMenuService.allMenus.where((menu) {
            /// 名前での検索：メニュー名に検索文字列が含まれるかチェック
            final nameMatch =
                query.isEmpty || menu.name.toLowerCase().contains(query);
            // カテゴリーでのフィルタリング：「すべて」選択時は全て表示，それ以外は一致するもののみ
            final categoryMatch =
                _selectedCategory == 'すべて' ||
                menu.category == _selectedCategory;
            // タイプでのフィルタリング：「すべて」選択時は全て表示，それ以外は一致するもののみ
            final typeMatch =
                _selectedType == 'すべて' || menu.type == _selectedType;
            // 難易度でのフィルタリング：「すべて」選択時は全て表示，それ以外は一致するもののみ
            final difficultyMatch =
                _selectedDifficulty == 'すべて' ||
                menu.difficulty == _selectedDifficulty;
            // 全ての条件を満たすメニューのみを返す（AND条件）
            return nameMatch && categoryMatch && typeMatch && difficultyMatch;
          }).toList();
    });
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: '練習メニューを検索',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  // フィルタリング機能
                  MenuFilterWidget(
                    selectedCategory: _selectedCategory,
                    selectedType: _selectedType,
                    selectedDifficulty: _selectedDifficulty,
                    onCategoryChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _filterMenus(); // フィルタリングを再実行
                      });
                    },
                    onTypeChanged: (value) {
                      setState(() {
                        _selectedType = value;
                        _filterMenus(); // フィルタリングを再実行
                      });
                    },
                    onDifficultyChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value;
                        _filterMenus(); // フィルタリングを再実行
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // フィルタリング後のメニューリスト
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '${_filteredMenus.length}件の練習メニュー',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // メニューリスト
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredMenus.length,
                      itemBuilder: (context, index) {
                        final menu = _filteredMenus[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(
                              menu.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(menu.description),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        menu.category,
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ColorHelpers.getTypeColor(
                                          menu.type,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        menu.type,
                                        style: TextStyle(
                                          color: ColorHelpers.getTypeColor(
                                            menu.type,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ColorHelpers.getDifficultyColor(
                                          menu.difficulty,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        menu.difficulty,
                                        style: TextStyle(
                                          color:
                                              ColorHelpers.getDifficultyColor(
                                                menu.difficulty,
                                              ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _navigateToDetailPage(menu),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
