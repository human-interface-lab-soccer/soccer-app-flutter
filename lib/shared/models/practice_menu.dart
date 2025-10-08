import 'package:uuid/uuid.dart';

// 練習メニューのデータクラス
class PracticeMenu {
  final String id;
  final String name; // タイトル（20字以内）
  final String description; // 説明（50字以内）
  final String category; // カテゴリー（10字以内）
  final String type; // メニュータイプ（既存のフィールド，必要に応じて使用）
  final String difficulty; // 難易度（初級・中級・上級）
  final int phaseCount; // フェーズ数（1〜8）
  final int ledCount; // LED数（1〜24）
  final List<List<String>> colorSettings; // 色設定データ [LED番号][フェーズ番号]

  static const int defaultPhaseCount = 4; // デフォルトのフェーズ数
  static const int defaultLedCount = 12; // デフォルトのLED数

  PracticeMenu({
    String? id,
    required this.name,
    required this.description,
    required this.category,
    this.type = '', // デフォルト値を設定
    required this.difficulty,
    required this.phaseCount,
    required this.ledCount,
    List<List<String>>? colorSettings,
  }) : id = id ?? const Uuid().v4(),
       colorSettings =
           colorSettings ??
           List.generate(
             ledCount,
             (_) => List.generate(phaseCount, (_) => 'クリア'),
           );

  // JSONからオブジェクトを生成するファクトリメソッド
  factory PracticeMenu.fromMap(Map<String, dynamic> json) {
    final phaseCount = json['phaseCount'] ?? defaultPhaseCount;
    final ledCount = json['ledCount'] ?? defaultLedCount;

    // colorSettingsの復元
    List<List<String>> colorSettings;
    if (json['colorSettings'] != null) {
      colorSettings =
          (json['colorSettings'] as List)
              .map((ledColors) => (ledColors as List).cast<String>().toList())
              .toList();
    } else {
      // colorSettingsがない場合はデフォルト値を生成
      colorSettings = List.generate(
        ledCount,
        (_) => List.generate(phaseCount, (_) => 'クリア'),
      );
    }

    return PracticeMenu(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      type: json['type'] ?? '',
      difficulty: json['difficulty'] ?? '初級',
      phaseCount: phaseCount,
      ledCount: ledCount,
      colorSettings: colorSettings,
    );
  }

  // オブジェクトをJSONに変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'type': type,
      'difficulty': difficulty,
      'phaseCount': phaseCount,
      'ledCount': ledCount,
      'colorSettings': colorSettings,
    };
  }

  // コピーメソッド（一部のフィールドを変更した新しいインスタンスを作成）
  PracticeMenu copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? type,
    String? difficulty,
    int? phaseCount,
    int? ledCount,
    List<List<String>>? colorSettings,
  }) {
    return PracticeMenu(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      phaseCount: phaseCount ?? this.phaseCount,
      ledCount: ledCount ?? this.ledCount,
      colorSettings: colorSettings ?? this.colorSettings,
    );
  }
}
