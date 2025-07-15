import 'package:uuid/uuid.dart';

// 練習メニューのデータクラス
class PracticeMenu {
  final String id;
  final String name;
  final String category;
  final String description;
  final String type;
  final String difficulty;
  final int phaseCount;
  static const int defaultPhaseCount = 4; // デフォルトのフェーズ数

  PracticeMenu({
    String? id,
    required this.name,
    required this.category,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.phaseCount,
  }) : id = id ?? const Uuid().v4();

  // JSONからオブジェクトを生成するファクトリメソッド
  factory PracticeMenu.fromMap(Map<String, dynamic> json) {
    return PracticeMenu(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      difficulty: json['difficulty'] ?? '',
      phaseCount: json['phaseCount'] ?? defaultPhaseCount,
    );
  }

  // オブジェクトをJSONに変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'type': type,
      'difficulty': difficulty,
      'phaseCount': phaseCount,
    };
  }
}
