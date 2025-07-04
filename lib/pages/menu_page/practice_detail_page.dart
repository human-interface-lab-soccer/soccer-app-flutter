import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/pages/menu_page/practice_menu_data.dart';

// 練習メニューの詳細ページ
class PracticeDetailPage extends StatefulWidget {
  final PracticeMenu menu;

  const PracticeDetailPage({super.key, required this.menu});

  @override
  State<PracticeDetailPage> createState() => _PracticeDetailPageState();
}

class _PracticeDetailPageState extends State<PracticeDetailPage> {
  List<Phase> _phases = [];

  @override
  void initState() {
    super.initState();
    // 初期フェーズを設定（デフォルトで3フェーズ）
    _phases = [
      Phase(name: 'ウォーミングアップ', duration: 300), // 5分
      Phase(name: 'メイン練習', duration: 1800), // 30分
      Phase(name: 'クールダウン', duration: 300), // 5分
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.menu.name),
      ),
      body: Column(
        children: [
          // 上部：メニューリストの内容を表示
          _buildMenuInfo(),

          // 中部：空白エリア
          const Expanded(child: SizedBox()),

          // 下部：パラメータ設定エリア
          _buildParameterSettings(),
        ],
      ),
    );
  }

  // メニュー情報を表示するウィジェット
  Widget _buildMenuInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.menu.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(widget.menu.description, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTag(
                widget.menu.category,
                Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _buildTag(widget.menu.type, _getTypeColor(widget.menu.type)),
              const SizedBox(width: 8),
              _buildTag(
                widget.menu.difficulty,
                _getDifficultyColor(widget.menu.difficulty),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // タグを作成するヘルパーメソッド
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  // パラメータ設定エリアを作成するウィジェット
  Widget _buildParameterSettings() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'フェーズ設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _addPhase,
                    icon: const Icon(Icons.add),
                    tooltip: 'フェーズを追加',
                  ),
                  Text(
                    '合計: ${_getTotalDuration()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // フェーズリスト
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _phases.length,
              itemBuilder: (context, index) {
                return _buildPhaseItem(index);
              },
            ),
          ),
          const SizedBox(height: 16),
          // 実行ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 練習開始処理
                _startPractice();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '練習開始',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // フェーズアイテムを作成するウィジェット
  Widget _buildPhaseItem(int index) {
    final phase = _phases[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // フェーズ番号
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // フェーズ名
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: phase.name,
                decoration: const InputDecoration(
                  labelText: 'フェーズ名',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _phases[index].name = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            // 時間設定
            Expanded(
              flex: 1,
              child: TextFormField(
                initialValue: phase.duration.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '時間（秒）',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _phases[index].duration = int.tryParse(value) ?? 0;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            // 削除ボタン
            if (_phases.length > 1)
              IconButton(
                onPressed: () => _removePhase(index),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'フェーズを削除',
              ),
          ],
        ),
      ),
    );
  }

  // フェーズを追加するメソッド
  void _addPhase() {
    setState(() {
      _phases.add(Phase(name: '新しいフェーズ', duration: 300));
    });
  }

  // フェーズを削除するメソッド
  void _removePhase(int index) {
    setState(() {
      _phases.removeAt(index);
    });
  }

  // 合計時間を計算するメソッド
  String _getTotalDuration() {
    final totalSeconds = _phases.fold(0, (sum, phase) => sum + phase.duration);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}分${seconds}秒';
  }

  // 練習開始処理
  void _startPractice() {
    // 空のフェーズがないかチェック
    if (_phases.any((phase) => phase.name.isEmpty || phase.duration <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('フェーズ名と時間を正しく入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 練習開始の確認ダイアログ
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('練習開始'),
            content: Text(
              '${widget.menu.name}を開始しますか？\n\n合計時間: ${_getTotalDuration()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // ここで実際の練習開始処理を実装
                  // 例: タイマーページへの遷移など
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.menu.name}を開始しました')),
                  );
                },
                child: const Text('開始'),
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

// フェーズクラス
class Phase {
  String name;
  int duration; // 秒単位

  Phase({required this.name, required this.duration});
}
