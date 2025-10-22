import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/constants/led_constants.dart';
import 'package:soccer_app_flutter/shared/enums/led_color.dart';

/// LEDグリッドウィジェット
/// LEDの表示ロジックを共通化したウィジェット
class LedGridWidget extends StatelessWidget {
  final PracticeMenu menu;
  final int currentPhaseIndex;
  final LedDisplayConfig config;

  const LedGridWidget({
    super.key,
    required this.menu,
    required this.currentPhaseIndex,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: config.spacing,
      runSpacing: config.spacing,
      alignment: WrapAlignment.center,
      children: List.generate(menu.ledCount, (ledIndex) => _buildLed(ledIndex)),
    );
  }

  /// 個別のLEDを構築
  Widget _buildLed(int ledIndex) {
    final String colorName = _getColorName(ledIndex);
    final Color ledColor = LedColor.fromLabel(colorName).baseColor;
    final bool isActive = LedColor.fromLabel(colorName).isActive;

    return Container(
      width: config.size,
      height: config.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ledColor,
        boxShadow: isActive ? _buildShadow(ledColor) : null,
        border: Border.all(
          color: isActive ? Colors.white : Colors.grey.shade300,
          width: config.borderWidth,
        ),
      ),
      child: Center(
        child: Text(
          '${ledIndex + 1}',
          style: TextStyle(
            color: LedColor.fromLabel(colorName).getContrastColor(),
            fontSize: config.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 指定されたLEDインデックスの色名を取得
  String _getColorName(int ledIndex) {
    final List<List<String>> colorSettings = menu.colorSettings;

    if (ledIndex < colorSettings.length &&
        currentPhaseIndex < colorSettings[ledIndex].length) {
      return colorSettings[ledIndex][currentPhaseIndex];
    }
    return LedColor.clear.label;
  }

  /// 影のエフェクトを構築
  List<BoxShadow> _buildShadow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: config.shadowAlpha),
        spreadRadius: config.shadowSpreadRadius,
        blurRadius: config.shadowBlurRadius,
        offset: const Offset(0, 0),
      ),
    ];
  }
}
