import 'dart:async';
import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';

/// LEDプレビューウィジェット
/// 1秒ごとにフェーズを自動切り替えして表示する簡易版
class LedPreviewWidget extends StatefulWidget {
  final PracticeMenu menu;

  const LedPreviewWidget({super.key, required this.menu});

  @override
  State<LedPreviewWidget> createState() => _LedPreviewWidgetState();
}

class _LedPreviewWidgetState extends State<LedPreviewWidget> {
  int _currentPhaseIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ///自動再生を開始
  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentPhaseIndex =
              (_currentPhaseIndex + 1) % widget.menu.phaseCount;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // プレビューラベル
          Text(
            'プレビュー（フェーズ ${_currentPhaseIndex + 1}/${widget.menu.phaseCount}）',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // LEDグリッド表示
          _buildLedGrid(),
        ],
      ),
    );
  }

  /// LEDグリッドの構築
  Widget _buildLedGrid() {
    final int ledCount = widget.menu.ledCount;
    final List<List<String>> colorSettings = widget.menu.colorSettings;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(ledCount, (ledIndex) {
        // 各LEDの現在のフェーズに対応する色を取得
        final String colorName =
            ledIndex < colorSettings.length &&
                    _currentPhaseIndex < colorSettings[ledIndex].length
                ? colorSettings[ledIndex][_currentPhaseIndex]
                : 'クリア';

        final Color ledColor = _colorNameToColor(colorName);
        return _buildLed(ledColor, ledIndex, colorName);
      }),
    );
  }

  /// 個別のLEDを構築（小さめサイズ）
  Widget _buildLed(Color color, int index, String colorName) {
    final bool isActive = colorName != 'クリア';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 0),
                  ),
                ]
                : null,
        border: Border.all(
          color: isActive ? Colors.white : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: _getContrastColor(color),
            fontSize: 12,
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
