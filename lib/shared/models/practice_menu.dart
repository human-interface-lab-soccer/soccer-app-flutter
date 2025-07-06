// 練習メニューのデータクラス
class PracticeMenu {
  final String name;
  final String category;
  final String description;
  final String type;
  final String difficulty;
  final int phaseCount;

  PracticeMenu({
    required this.name,
    required this.category,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.phaseCount,
  });

  // JSONからオブジェクトを生成するファクトリメソッド
  factory PracticeMenu.fromJson(Map<String, dynamic> json) {
    return PracticeMenu(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      difficulty: json['difficulty'] ?? '',
      phaseCount: json['phaseCount'] ?? 4,
    );
  }

  // オブジェクトをJSONに変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'type': type,
      'difficulty': difficulty,
      'phaseCount': phaseCount,
    };
  }
}
