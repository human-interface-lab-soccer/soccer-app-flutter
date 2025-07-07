import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/controllers/practice_timer_controller.dart';

/// 練習アクションボタンウィジェット
class PracticeActionButtons extends StatelessWidget {
  final PracticeTimerController controller;

  const PracticeActionButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.isRunning) {
      return _buildStartButton(context);
    } else {
      return _buildControlButtons(context);
    }
  }

  /// 開始ボタンの構築
  Widget _buildStartButton(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => controller.startPractice(),
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
  }

  /// コントロールボタンの構築
  Widget _buildControlButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildPreviousButton()),
        const SizedBox(width: 8),
        Expanded(child: _buildPauseResumeButton()),
        const SizedBox(width: 8),
        Expanded(child: _buildNextButton()),
        const SizedBox(width: 8),
        Expanded(child: _buildStopButton()),
      ],
    );
  }

  /// 前のフェーズボタンの構築
  Widget _buildPreviousButton() {
    return ElevatedButton(
      onPressed: () => controller.previousPhase(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Icon(Icons.skip_previous, size: 24),
    );
  }

  /// 一時停止/再開ボタンの構築
  Widget _buildPauseResumeButton() {
    return ElevatedButton(
      onPressed: () => controller.pauseResumePractice(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Icon(
        controller.isPaused ? Icons.play_arrow : Icons.pause,
        size: 24,
      ),
    );
  }

  /// 次のフェーズボタンの構築
  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: () => controller.nextPhase(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Icon(Icons.skip_next, size: 24),
    );
  }

  /// 停止ボタンの構築
  Widget _buildStopButton() {
    return ElevatedButton(
      onPressed: () => controller.stopPractice(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Icon(Icons.stop, size: 24),
    );
  }
}
