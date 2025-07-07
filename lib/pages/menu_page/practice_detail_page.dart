import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/utils/color_helpers.dart';
import 'package:soccer_app_flutter/shared/widgets/practice_timer_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/progress_meter_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/time_picker_widget.dart';
import 'package:soccer_app_flutter/shared/controllers/practice_timer_controller.dart';

// 練習メニューの詳細ページ
class PracticeDetailPage extends StatefulWidget {
  final PracticeMenu menu;

  const PracticeDetailPage({super.key, required this.menu});

  @override
  State<PracticeDetailPage> createState() => _PracticeDetailPageState();
}

class _PracticeDetailPageState extends State<PracticeDetailPage>
    with TickerProviderStateMixin {
  late PracticeTimerController _controller;
  late List<Color> _phaseColors;

  // 初期設定値
  final int _initialPhaseSeconds = 10;
  final int _initialTimerMinutes = 3;
  final int _initialTimerSeconds = 0;

  @override
  void initState() {
    super.initState();

    // コントローラーの初期化
    _controller = PracticeTimerController();
    _controller.initialize(
      widget.menu.phaseCount,
      _initialPhaseSeconds,
      _initialTimerMinutes,
      _initialTimerSeconds,
      this,
    );

    // フェーズカラーを設定
    _phaseColors = ColorHelpers.getPhaseColors();

    // コントローラーの変更を監視
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
            // 右にスワイプした場合，前のページに戻る
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
          if (_controller.isRunning)
            PracticeTimerWidget(
              currentTimerSeconds: _controller.currentTimerSeconds,
              timerAnimation: _controller.timerAnimation,
            ),

          // プログレスメーター
          ProgressMeterWidget(
            totalPhases: _controller.totalPhases,
            currentPhaseIndex: _controller.currentPhaseIndex,
            phaseColors: _phaseColors,
            meterAnimation: _controller.meterAnimation,
            isRunning: _controller.isRunning,
          ),

          const SizedBox(height: 16),

          // コンパクトなフェーズ時間設定
          if (!_controller.isRunning)
            TimePickerWidget(
              title: 'フェーズ時間',
              initialMinutes: _controller.phaseSeconds ~/ 60,
              initialSeconds: _controller.phaseSeconds % 60,
              onTimeChanged: (minutes, seconds) {
                // 0:00を許容しない
                if (minutes == 0 && seconds == 0) {
                  _controller.updatePhaseSeconds(1);
                } else {
                  _controller.updatePhaseSeconds(minutes * 60 + seconds);
                }
              },
            ),

          // タイマー設定
          if (!_controller.isRunning)
            TimePickerWidget(
              title: 'タイマー設定',
              initialMinutes: _controller.timerMinutes,
              initialSeconds: _controller.timerSeconds,
              onTimeChanged: (minutes, seconds) {
                _controller.updateTimerTime(minutes, seconds);
              },
            ),

          const SizedBox(height: 16),

          // 実行ボタン
          _buildActionButtons(),
        ],
      ),
    );
  }

  // アクションボタンを表示するウィジェット
  Widget _buildActionButtons() {
    if (!_controller.isRunning) {
      // 練習前：開始ボタンのみ（大きく）
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _controller.startPractice(),
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
              onPressed: () => _controller.previousPhase(),
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
              onPressed: () => _controller.pauseResumePractice(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Icon(
                _controller.isPaused ? Icons.play_arrow : Icons.pause,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 次のフェーズに進むボタン
          Expanded(
            child: ElevatedButton(
              onPressed: () => _controller.nextPhase(),
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
              onPressed: () => _controller.stopPractice(),
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
}
