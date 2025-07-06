import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:soccer_app_flutter/shared/model/practice_menu.dart';
import 'package:soccer_app_flutter/utils/color_helper.dart';
import 'package:soccer_app_flutter/utils/time_helper.dart';

// 練習メニューの詳細ページ
class PracticeDetailPage extends StatefulWidget {
  final PracticeMenu menu;

  const PracticeDetailPage({super.key, required this.menu});

  @override
  State<PracticeDetailPage> createState() => _PracticeDetailPageState();
}

class _PracticeDetailPageState extends State<PracticeDetailPage>
    with TickerProviderStateMixin {
  int _phaseSeconds = 10; // 各フェーズの秒数
  int _timerMinutes = 3; // タイマーの分数
  int _timerSeconds = 0; // タイマーの秒数
  late AnimationController _meterController;
  late AnimationController _timerController;
  late Animation<double> _meterAnimation;
  late Animation<double> _timerAnimation;
  bool _isRunning = false;
  bool _isPaused = false;
  int _currentPhaseIndex = 0;
  late int _totalPhases;
  late List<Color> _phaseColors;
  late int _totalTimerSeconds;
  late int _currentTimerSeconds;

  @override
  void initState() {
    super.initState();

    // practice_menu_data.dartからフェーズ数を取得
    _totalPhases = widget.menu.phaseCount;
    _totalTimerSeconds = TimeHelpers.getTotalSeconds(
      _timerMinutes,
      _timerSeconds,
    );
    _currentTimerSeconds = _totalTimerSeconds;

    // フェーズカラーを設定
    _phaseColors = ColorHelpers.getPhaseColors();

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

    // タイマーアニメーションの設定
    _timerController = AnimationController(
      duration: Duration(seconds: _totalTimerSeconds),
      vsync: this,
    );

    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _timerController, curve: Curves.linear));

    _timerController.addListener(() {
      setState(() {
        _currentTimerSeconds =
            (_totalTimerSeconds * (1.0 - _timerController.value)).round();
      });
    });

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // タイマー終了時の処理
        _stopPractice();
      }
    });
  }

  @override
  void dispose() {
    _meterController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.menu.name),
      ),
      body: GestureDetector(
        // スワイプで戻る機能
        onHorizontalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx > 300) {
            // 右にスワイプした場合、前のページに戻る
            Navigator.of(context).pop();
          }
        },
        child: Column(
          children: [
            // 上部：メニューリストの内容を表示
            _buildMenuInfo(),

            // 中部：空白エリア
            const Expanded(child: SizedBox()),

            // 下部：コンパクトなパラメータ設定エリア
            _buildCompactParameterSettings(),
          ],
        ),
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
            color: Colors.grey.withValues(alpha: 0.1),
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
              _buildTag(
                widget.menu.type,
                ColorHelpers.getTypeColor(widget.menu.type),
              ),
              const SizedBox(width: 8),
              _buildTag(
                widget.menu.difficulty,
                ColorHelpers.getDifficultyColor(widget.menu.difficulty),
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
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイマー設定
          if (_isRunning) _buildTimerDisplay(),
          // プログレスメーター
          _buildProgressMeter(),

          const SizedBox(height: 16),

          // コンパクトなフェーズ時間設定
          if (!_isRunning) _buildCompactPhaseTimeSetting(),

          // タイマー設定
          if (!_isRunning) _buildTimerSetting(),

          const SizedBox(height: 16),

          // 実行ボタン
          _buildActionButtons(),
        ],
      ),
    );
  }

  // タイマー表示
  Widget _buildTimerDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '残り時間',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              TimeHelpers.formatTime(_currentTimerSeconds),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color:
                    _currentTimerSeconds < 30
                        ? Colors.red
                        : _currentTimerSeconds < 60
                        ? Colors.orange
                        : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // タイマープログレスバー
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: AnimatedBuilder(
            animation: _timerAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _timerAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        _currentTimerSeconds < 30
                            ? Colors.red
                            : _currentTimerSeconds < 60
                            ? Colors.orange
                            : Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
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
              '$_totalPhasesフェーズ',
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
                  final isCompleted = index < _currentPhaseIndex;
                  final color = _phaseColors[index % _phaseColors.length];

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Stack(
                        children: [
                          if (isCompleted)
                            Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(13),
                              ),
                            )
                          else if (isCurrentPhase)
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _meterAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            ),
                          Center(
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
                        ],
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
                'フェーズ ${_currentPhaseIndex + 1}/$_totalPhases',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ],
    );
  }

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
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 分ピッカー
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: minutes,
                  ),
                  itemExtent: 32,
                  onSelectedItemChanged: (value) {
                    setState(() {
                      int newSeconds = _phaseSeconds % 60;
                      if (value == 0 && newSeconds == 0) newSeconds = 1;
                      _phaseSeconds = value * 60 + newSeconds;
                      _updateMeterDuration();
                    });
                  },
                  children: List.generate(
                    61,
                    (index) => Center(child: Text('$index')),
                  ),
                ),
              ),
              const Text(
                ':',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // 秒ピッカー
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: seconds,
                  ),
                  itemExtent: 32,
                  onSelectedItemChanged: (value) {
                    setState(() {
                      int newMinutes = _phaseSeconds ~/ 60;
                      if (value == 0 && newMinutes == 0) value = 1;
                      _phaseSeconds = newMinutes * 60 + value;
                      _updateMeterDuration();
                    });
                  },
                  children: List.generate(
                    60,
                    (index) => Center(child: Text('$index')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // タイマー設定ウィジェット
  Widget _buildTimerSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'タイマー設定',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 分ピッカー
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: _timerMinutes,
                  ),
                  itemExtent: 32,
                  onSelectedItemChanged: (value) {
                    setState(() {
                      _timerMinutes = value;
                      _updateTimerDuration();
                    });
                  },
                  children: List.generate(
                    61,
                    (index) => Center(child: Text('$index')),
                  ),
                ),
              ),
              const Text(
                ':',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // 秒ピッカー
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: _timerSeconds,
                  ),
                  itemExtent: 32,
                  onSelectedItemChanged: (value) {
                    setState(() {
                      _timerSeconds = value;
                      _updateTimerDuration();
                    });
                  },
                  children: List.generate(
                    60,
                    (index) => Center(child: Text('$index')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // アクションボタンを表示するウィジェット
  Widget _buildActionButtons() {
    if (!_isRunning) {
      // 練習前：開始ボタンのみ（大きく）
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _startPractice,
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
      );
    } else {
      // 練習中または一時停止中：4つのボタン（大きめボタンに統一）
      return Row(
        children: [
          // 前のフェーズに戻るボタン
          Expanded(
            child: ElevatedButton(
              onPressed: _previousPhase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Icon(Icons.skip_previous, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          // 一時停止/再開ボタン
          Expanded(
            child: ElevatedButton(
              onPressed: _pauseResumePractice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          // 次のフェーズに進むボタン
          Expanded(
            child: ElevatedButton(
              onPressed: _nextPhase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Icon(Icons.skip_next, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          // 練習停止ボタン
          Expanded(
            child: ElevatedButton(
              onPressed: _stopPractice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Icon(Icons.stop, size: 24),
            ),
          ),
        ],
      );
    }
  }

  // 前のフェーズに戻る
  void _previousPhase() {
    setState(() {
      if (_currentPhaseIndex > 0) {
        _currentPhaseIndex--;
      } else {
        _currentPhaseIndex = _totalPhases - 1; // 最後のフェーズに戻る
      }
    });

    if (_isRunning && !_isPaused) {
      _meterController.reset();
      _meterController.forward();
    }
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

    if (_isRunning && !_isPaused) {
      _meterController.reset();
      _meterController.forward();
    }
  }

  // 一時停止/再開処理
  void _pauseResumePractice() {
    setState(() {
      if (_isPaused) {
        _meterController.forward();
        _timerController.forward();
        _isPaused = false;
      } else {
        _meterController.stop();
        _timerController.stop();
        _isPaused = true;
      }
    });
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

  // タイマーの継続時間を更新
  void _updateTimerDuration() {
    _totalTimerSeconds = _timerMinutes * 60 + _timerSeconds;
    _currentTimerSeconds = _totalTimerSeconds;
    _timerController.duration = Duration(seconds: _totalTimerSeconds);
  }

  // 練習開始処理
  void _startPractice() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _currentPhaseIndex = 0;
      _currentTimerSeconds = _totalTimerSeconds;
    });
    _meterController.reset();
    _meterController.forward();
    _timerController.reset();
    _timerController.forward();
  }

  // 練習停止処理
  void _stopPractice() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _currentPhaseIndex = 0;
      _currentTimerSeconds = _totalTimerSeconds;
    });
    _meterController.stop();
    _meterController.reset();
    _timerController.stop();
    _timerController.reset();
  }
}
