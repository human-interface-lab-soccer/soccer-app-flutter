import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/utils/time_helpers.dart';

// 練習タイマーウィジェット
class PracticeTimerWidget extends StatelessWidget {
  final int currentTimerSeconds;
  final Animation<double> timerAnimation;

  const PracticeTimerWidget({
    super.key,
    required this.currentTimerSeconds,
    required this.timerAnimation,
  });

  @override
  Widget build(BuildContext context) {
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
              TimeHelpers.formatTime(currentTimerSeconds),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getTimerColor(),
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
            animation: timerAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: timerAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getTimerColor(),
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

  Color _getTimerColor() {
    if (currentTimerSeconds < 30) {
      return Colors.red;
    } else if (currentTimerSeconds < 60) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}
