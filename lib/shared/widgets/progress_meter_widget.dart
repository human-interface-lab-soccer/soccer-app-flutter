import 'package:flutter/material.dart';

// プログレスメーターウィジェット
class ProgressMeterWidget extends StatelessWidget {
  final int totalPhases;
  final int currentPhaseIndex;
  final List<Color> phaseColors;
  final Animation<double> meterAnimation;
  final bool isRunning;

  const ProgressMeterWidget({
    super.key,
    required this.totalPhases,
    required this.currentPhaseIndex,
    required this.phaseColors,
    required this.meterAnimation,
    required this.isRunning,
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
              'プログレス',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              '${totalPhases}フェーズ',
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
            animation: meterAnimation,
            builder: (context, child) {
              return Row(
                children: List.generate(totalPhases, (index) {
                  final isCurrentPhase = index == currentPhaseIndex;
                  final isCompleted = index < currentPhaseIndex;
                  final color = phaseColors[index % phaseColors.length];

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
                              widthFactor: meterAnimation.value,
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
                                                meterAnimation.value > 0.5))
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
        if (isRunning) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '現在のフェーズ：${currentPhaseIndex + 1}',
                style: TextStyle(
                  fontSize: 14,
                  color: phaseColors[currentPhaseIndex % phaseColors.length],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'フェーズ ${currentPhaseIndex + 1}/$totalPhases',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
