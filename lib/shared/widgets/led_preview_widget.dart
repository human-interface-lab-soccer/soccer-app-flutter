import 'dart:async';
import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/utils/led_utils.dart';
import 'package:soccer_app_flutter/shared/widgets/led_grid_widget.dart';

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

  /// 自動再生を開始
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
          _buildPreviewLabel(),
          const SizedBox(height: 16),
          LedGridWidget(
            menu: widget.menu,
            currentPhaseIndex: _currentPhaseIndex,
            config: LedDisplayConfig.small,
          ),
        ],
      ),
    );
  }

  /// プレビューラベルを構築
  Widget _buildPreviewLabel() {
    return Text(
      'プレビュー（フェーズ ${_currentPhaseIndex + 1}/${widget.menu.phaseCount}）',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
