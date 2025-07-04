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
    required this.difficulty,
  });
}

// 練習メニューのデータを管理するクラス
class PracticeMenuData {
  static final List<PracticeMenu> allMenus = [
    PracticeMenu(
      name: 'ドリブル練習',
      category: '基礎技術',
      description: 'ドリブルの基本を学ぶ練習です。',
      type: '既存',
      difficulty: '初級',
    ),
    PracticeMenu(
      name: 'パス練習',
      category: '基礎技術',
      description: 'パスの精度を高めるための練習です。',
      type: '既存',
      difficulty: '初級',
    ),
    PracticeMenu(
      name: 'シュート練習',
      category: '攻撃技術',
      description: 'シュートのフォームと精度を向上させる練習です。',
      type: '既存',
      difficulty: '中級',
    ),
    // 他のメニューも追加可能
  ];

  // 
  static List<String> getCategories() {
    return allMenus.map((menu) => menu.category).toSet().toList();
  }

  static List<String> getTypes() {
    return allMenus.map((menu) => menu.type).toSet().toList();
  }

  static List<String> getDifficulties() {
    return allMenus.map((menu) => menu.difficulty).toSet().toList();
  }
}