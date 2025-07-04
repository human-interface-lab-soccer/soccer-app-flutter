import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/pages/menu_page/practice_menu_data.dart';

// 練習メニューの詳細ページ
class PracticeDetailPage extends StatefulWidget {
  final PracticeMenu menu;

  const PracticeDetailPage({super.key, required this.menu});

  @override
  State<PracticeDetailPage> createState() => _PracticeDetailPageState();
}

class _PracticeDetailPageState extends State<PracticeDetailPage>
    with TickerProviderStateMixin {
  int _phaseSeconds = 30; // 各フェーズの秒数
  late AnimationController _meterController;
  late Animation<double> _meterAnimation;
  bool _isRunning = false;
  int _currentPhaseIndex = 0;
  late int _totalPhases;
  late List<Color> _phaseColors;

  @override
  void initState() {
    super.initState();

    // practice_menu_data.dartからフェーズ数を取得
    _totalPhases = widget.menu.phaseCount;

    // フェーズカラーを設定
    _phaseColors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];

    // メーターアニメーションの設定
    _meterController = AnimationController(
      duration: Duration(seconds: _phaseSeconds),
      vsync: this,
    );

    _meterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _meterController, curve: Curves.linear));

    _meterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextPhase();
      }
    });
  }

  @override
  void dispose() {
    _meterController.dispose();
    super.dispose();
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

          // 下部：コンパクトなパラメータ設定エリア
          _buildCompactParameterSettings(),
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

  // コンパクトなパラメータ設定エリア
  Widget _buildCompactParameterSettings() {
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
          // プログレスメーター
          _buildProgressMeter(),

          const SizedBox(height: 16),

          // コンパクトなフェーズ時間設定
          _buildCompactPhaseTimeSetting(),

          const SizedBox(height: 16),

          // 実行ボタン
          _buildActionButtons(),
        ],
      ),
    );
  }

  // プログレスメーター
  Widget _buildProgressMeter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'プログレス',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              '${_totalPhases}フェーズ',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // プログレスバー
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(15),
          ),
          child: AnimatedBuilder(
            animation: _meterAnimation,
            builder: (context, child) {
              return Row(
                children: List.generate(_totalPhases, (index) {
                  final isCurrentPhase = index == _currentPhaseIndex;
                  final color = _phaseColors[index % _phaseColors.length];
                  final isCompleted = index < _currentPhaseIndex;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      height: 26,
                      decoration: BoxDecoration(
                        color:
                            isCompleted
                                ? color
                                : isCurrentPhase
                                ? Color.lerp(
                                  Colors.grey.shade200,
                                  color,
                                  _meterAnimation.value,
                                )
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color:
                                (isCompleted ||
                                        (isCurrentPhase &&
                                            _meterAnimation.value > 0.5))
                                    ? Colors.white
                                    : Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // 現在のフェーズ情報
        if (_isRunning) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '現在のフェーズ：${_currentPhaseIndex + 1}',
                style: TextStyle(
                  fontSize: 14,
                  color: _phaseColors[_currentPhaseIndex % _phaseColors.length],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'フェーズ ${_currentPhaseIndex + 1}/${_totalPhases}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // コンパクトなフェーズ時間設定
  Widget _buildCompactPhaseTimeSetting() {
    final minutes = _phaseSeconds ~/ 60;
    final seconds = _phaseSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'フェーズ時間',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 時間表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            // 時間調整ボタン
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_phaseSeconds > 1) {
                      setState(() {
                        _phaseSeconds = (_phaseSeconds - 1).clamp(1, 3600);
                      });
                      _updateMeterDuration();
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _phaseSeconds = (_phaseSeconds + 1).clamp(1, 3600);
                    });
                    _updateMeterDuration();
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 合計時間
        Text(
          '合計練習時間：${_formatTotalTime(_totalPhases * _phaseSeconds)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // 合計時間をフォーマットするヘルパーメソッド
  String _formatTotalTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '${minutes}分${seconds}秒';
    } else {
      return '${seconds}秒';
    }
  }

  // アクションボタン
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isRunning ? _stopPractice : _startPractice,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isRunning
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _isRunning ? '停止' : '練習開始',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (_isRunning) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed:
                _meterController.isAnimating
                    ? _meterController.stop
                    : _meterController.forward,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
            child: Icon(
              _meterController.isAnimating ? Icons.pause : Icons.play_arrow,
            ),
          ),
        ],
      ],
    );
  }

  // 次のフェーズに進む
  void _nextPhase() {
    setState(() {
      if (_currentPhaseIndex < _totalPhases - 1) {
        _currentPhaseIndex++;
      } else {
        _currentPhaseIndex = 0; // 最初のフェーズに戻る
      }
    });

    if (_isRunning) {
      _meterController.reset();
      _meterController.forward();
    }
  }

  // メーターの継続時間を更新
  void _updateMeterDuration() {
    if (_meterController.isAnimating) {
      _meterController.stop();
      _meterController.duration = Duration(seconds: _phaseSeconds);
      _meterController.forward();
    } else {
      _meterController.duration = Duration(seconds: _phaseSeconds);
    }
  }

  // 練習開始処理
  void _startPractice() {
    setState(() {
      _isRunning = true;
      _currentPhaseIndex = 0;
    });
    _meterController.reset();
    _meterController.forward();
  }

  // 練習停止処理
  void _stopPractice() {
    setState(() {
      _isRunning = false;
      _currentPhaseIndex = 0;
    });
    _meterController.stop();
    _meterController.reset();
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
