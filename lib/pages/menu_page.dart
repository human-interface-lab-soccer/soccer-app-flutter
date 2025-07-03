import 'package:flutter/material.dart';

// 練習メニューのデータクラス
class PracticeMenu {
  final String name;
  final String category;
  final String description;
  final String type;
  final String difficulty;

  PracticeMenu({
    required this.name,
    required this.category,
    required this.description,
    required this.type,
    required this.difficulty
  });
}

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

  // デモ用の練習メニューデータ
  final List<PracticeMenu> _allMenus = [
    PracticeMenu(
      name: '基礎ドリブル練習',
      category: '基礎技術',
      description: 'ボールコントロールの基本を身につける練習です．両足でのドリブルを重点的に行います．',
      type: '既存',
      difficulty: '初級',
    ),
    PracticeMenu(
      name: 'パス&ムーブ',
      category: '戦術',
      description: '正確なパスとポジショニングを組み合わせた練習です．チームプレイの基本を学びます．',
      type: '既存',
      difficulty: '中級',
    ),
    PracticeMenu(
      name: 'シュート練習',
      category: '得点技術',
      description: 'ゴール前での決定力を向上させる練習です．様々な角度からのシュートを練習します．',
      type: '既存',
      difficulty: '中級',
    ),
    PracticeMenu(
      name: 'フィジカルトレーニング',
      category: '体力強化',
      description: '持久力と筋力を向上させる総合的なトレーニングです．',
      type: '既存',
      difficulty: '上級',
    ),
    PracticeMenu(
      name: '1対1練習',
      category: '実戦技術',
      description: '対人プレイでの判断力と技術を磨く練習です．攻守の切り替えを重点的に行います．',
      type: '自由帳',
      difficulty: '上級',
    ),
    PracticeMenu(
      name: 'ボールタッチ練習',
      category: '基礎技術',
      description: 'ボールの感覚を養う基本的な練習です．初心者におすすめです．',
      type: '自由帳',
      difficulty: '初級',
    ),
    PracticeMenu(
      name: 'クロス&ヘディング',
      category: '得点技術',
      description: 'サイドからのクロスとヘディングの連携練習です．',
      type: '自由帳',
      difficulty: '中級',
    ),
    PracticeMenu(
      name: 'ディフェンス練習',
      category: '守備技術',
      description: '組織的な守備の基本を身につける練習です．ポジショニングを重視します．',
      type: '自由帳',
      difficulty: '中級',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 初期状態ではすべてのメニューを表示
    _filteredMenus = _allMenus; 
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
      _filteredMenus = _allMenus.where((menu) {
        /// 名前での検索：メニュー名に検索文字列が含まれるかチェック
        final nameMatch = menu.name.toLowerCase().contains(query);
        // カテゴリーでのフィルタリング：「すべて」選択時は全て表示，それ以外は一致するもののみ
        final categoryMatch = _selectedCategory == 'すべて' || menu.category == _selectedCategory;
        // タイプでのフィルタリング：「すべて」選択時は全て表示，それ以外は一致するもののみ
        final typeMatch = _selectedType == 'すべて' || menu.type == _selectedType;
        // 難易度でのフィルタリング：「すべて」選択時は全て表示，それ以外は一致するもののみ
        final difficultyMatch = _selectedDifficulty == 'すべて' || menu.difficulty == _selectedDifficulty;
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
                        items: <String>['すべて', '基礎技術', '戦術', '得点技術', '体力強化', '実戦技術', '守備技術']
                            .map((String category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
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
                        items: <String>['すべて', '既存', '自由帳']
                            .map((String type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                ))
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
                        items: <String>['すべて', '初級', '中級', '上級']
                            .map((String difficulty) => DropdownMenuItem<String>(
                                  value: difficulty,
                                  child: Text(difficulty),
                                ))
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
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getTypeColor(menu.type).withValues(alpha: 0.1),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(menu.difficulty).withValues(alpha: 0.1),
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