import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';

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
          // LEDグリッド表示
          _buildLedGrid(),
        ],
      ),
    );
  }

  /// LEDグリッドの構築
  Widget _buildLedGrid() {
    final int ledCount = menu.ledCount;
    final List<List<String>> colorSettings = menu.colorSettings;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(ledCount, (ledIndex) {
        // 各LEDの現在のフェーズに対応する色を取得
        final String colorName =
            ledIndex < colorSettings.length &&
                    currentPhaseIndex < colorSettings[ledIndex].length
                ? colorSettings[ledIndex][currentPhaseIndex]
                : 'クリア';

        final Color ledColor = _colorNameToColor(colorName);
        return _buildLed(ledColor, ledIndex, colorName);
      }),
    );
  }

  /// 個別のLEDを構築
  Widget _buildLed(Color color, int index, String colorName) {
    final bool isActive = colorName != 'クリア';

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ]
                : null,
        border: Border.all(
          color: isActive ? Colors.white : Colors.grey.shade300,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: _getContrastColor(color),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 色名をColorに変換
  Color _colorNameToColor(String colorName) {
    switch (colorName) {
      case '赤':
        return Colors.red;
      case '青':
        return Colors.blue;
      case '緑':
        return Colors.green;
      case 'クリア':
      default:
        return Colors.grey.shade200;
    }
  }

  /// 背景色に対して見やすい文字色を取得
  Color _getContrastColor(Color backgroundColor) {
    final double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
