import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/controllers/practice_timer_controller.dart';
import 'package:soccer_app_flutter/shared/utils/color_helpers.dart';
import 'package:soccer_app_flutter/shared/widgets/practice_timer_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/progress_meter_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/time_picker_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/practice_action_buttons_widget.dart';

/// 練習パラメータ設定エリア
class PracticeParameterSettingsWidget extends StatelessWidget {
  final PracticeTimerController controller;

  const PracticeParameterSettingsWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
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
          _buildTimerWidget(),
          _buildProgressMeter(),
          const SizedBox(height: 16),
          _buildTimeSettings(),
          const SizedBox(height: 16),
          PracticeActionButtonsWidget(controller: controller),
        ],
      ),
    );
  }

  /// タイマーウィジェットの構築
  Widget _buildTimerWidget() {
    if (controller.isRunning) {
      return PracticeTimerWidget(
        currentTimerSeconds: controller.currentTimerSeconds,
        timerAnimation: controller.timerAnimation,
      );
    }
    return const SizedBox.shrink();
  }

  /// プログレスメーターの構築
  Widget _buildProgressMeter() {
    return ProgressMeterWidget(
      totalPhases: controller.totalPhases,
      currentPhaseIndex: controller.currentPhaseIndex,
      phaseColors: ColorHelpers.getPhaseColors(),
      meterAnimation: controller.meterAnimation,
      isRunning: controller.isRunning,
    );
  }

  /// 時間設定の構築
  Widget _buildTimeSettings() {
    if (controller.isRunning) {
      return const SizedBox.shrink();
    }

    return Column(children: [_buildPhaseTimeSettings(), _buildTimerSettings()]);
  }

  /// フェーズ時間設定の構築
  Widget _buildPhaseTimeSettings() {
    return TimePickerWidget(
      title: 'フェーズ時間',
      initialMinutes: controller.phaseSeconds ~/ 60,
      initialSeconds: controller.phaseSeconds % 60,
      onTimeChanged: (minutes, seconds) {
        _updatePhaseTime(minutes, seconds);
      },
    );
  }

  /// タイマー設定の構築
  Widget _buildTimerSettings() {
    return TimePickerWidget(
      title: 'タイマー設定',
      initialMinutes: controller.timerMinutes,
      initialSeconds: controller.timerSeconds,
      onTimeChanged: (minutes, seconds) {
        _updateTimerTime(minutes, seconds);
      },
    );
  }

  /// フェーズ時間の更新処理
  void _updatePhaseTime(int minutes, int seconds) {
    // 0:00を許容しない
    if (minutes == 0 && seconds == 0) {
      controller.updatePhaseSeconds(1);
    } else {
      controller.updatePhaseSeconds(minutes * 60 + seconds);
    }
  }

  /// タイマー時間の更新処理
  void _updateTimerTime(int minutes, int seconds) {
    // 0:00を許容しない
    if (minutes == 0 && seconds == 0) {
      controller.updateTimerTime(1, 0);
    } else {
      controller.updateTimerTime(minutes, seconds);
    }
  }
}
