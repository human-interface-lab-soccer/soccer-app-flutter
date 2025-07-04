import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/pages/menu_page/practice_menu_data.dart';

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

  @override
  void initState() {
    super.initState();
    // 初期状態ではすべてのメニューを表示
    _filteredMenus = PracticeMenuData.allMenus;
    // 検索テキストフィールドの変更を監視してフィルタリング実行
    _searchController.addListener(_filterMenus);
  }

  @override
  void dispose() {
    // テキストコントローラーのリソースを解放
    _searchController.dispose();
    super.dispose();
  }

  void _filterMenus() {
    // 検索テキストを小文字に変換（大文字小文字を区別しない検索のため）
    final query = _searchController.text.toLowerCase();
    setState(() {
      // 全メニューから条件に合致するものだけを抽出
      _filteredMenus =
          PracticeMenuData.allMenus.where((menu) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("menuPage"),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('練習メニュー一覧'),
      ),
      body: Column(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // カテゴリ選択ドロップダウン
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('カテゴリ'),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        items:
                            ['すべて', ...PracticeMenuData.getCategories()]
                                .map(
                                  (String category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue!;
                            _filterMenus();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // タイプ選択ドロップダウン
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('タイプ'),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        items:
                            ['すべて', ...PracticeMenuData.getTypes()]
                                .map(
                                  (String type) => DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedType = newValue!;
                            _filterMenus();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 難易度選択ドロップダウン
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('難易度'),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _selectedDifficulty,
                        isExpanded: true,
                        items:
                            ['すべて', ...PracticeMenuData.getDifficulties()]
                                .map(
                                  (String difficulty) =>
                                      DropdownMenuItem<String>(
                                        value: difficulty,
                                        child: Text(difficulty),
                                      ),
                                )
                                .toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDifficulty = newValue!;
                            _filterMenus();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                menu.category,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
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
                                color: _getTypeColor(
                                  menu.type,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                menu.type,
                                style: TextStyle(
                                  color: _getTypeColor(menu.type),
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
                                color: _getDifficultyColor(
                                  menu.difficulty,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                menu.difficulty,
                                style: TextStyle(
                                  color: _getDifficultyColor(menu.difficulty),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      // 練習メニューの詳細ページへの遷移などを実装可能
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${menu.name}が選択されました')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // タイプに応じた色を返すヘルパーメソッド
  Color _getTypeColor(String type) {
    switch (type) {
      case '既存':
        return Colors.blue;
      case '自由帳':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 難易度に応じた色を返すヘルパーメソッド
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '初級':
        return Colors.green;
      case '中級':
        return Colors.orange;
      case '上級':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
