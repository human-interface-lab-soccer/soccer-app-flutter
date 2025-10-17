import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/utils/led_utils.dart';
import 'package:soccer_app_flutter/shared/widgets/led_grid_widget.dart';

/// LEDディスプレイウィジェット
/// フェーズに応じたLED表示を行う
class LedDisplayWidget extends StatelessWidget {
  final PracticeMenu menu;
  final int currentPhaseIndex;

  const LedDisplayWidget({
    super.key,
    required this.menu,
    required this.currentPhaseIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LedGridWidget(
            menu: menu,
            currentPhaseIndex: currentPhaseIndex,
            config: LedDisplayConfig.normal,
          ),
        ],
      ),
    );
  }
}
