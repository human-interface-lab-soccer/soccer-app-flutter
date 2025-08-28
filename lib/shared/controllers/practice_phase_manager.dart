import 'package:flutter/material.dart';

// 練習フェーズを管理
class PracticePhaseManager with ChangeNotifier {
  int _phaseSeconds = 10;
  int _currentPhaseIndex = 0;
  late int _totalPhases;
  late AnimationController _controller;
  late Animation<double> _animation;

  // ゲッター
  int get phaseSeconds => _phaseSeconds;
  int get currentPhaseIndex => _currentPhaseIndex;
  int get totalPhases => _totalPhases;
  Animation<double> get animation => _animation;

  // 初期化
  void initialize(int totalPhases, AnimationController controller) {
    _totalPhases = totalPhases;
    _controller = controller;

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        nextPhase();
      }
    });
  }

  // フェーズ時間を更新
  void updatePhaseSeconds(int seconds) {
    if (seconds <= 0) return;
    _phaseSeconds = seconds;
    _updateDuration();
    notifyListeners();
  }

  // フェーズ開始
  void startPhase() {
    _currentPhaseIndex = 0;
    _controller.reset();
    _controller.forward();
  }

  // フェーズ停止
  void stopPhase() {
    _controller.stop();
    _controller.reset();
    _currentPhaseIndex = 0;
  }

  // 一時停止・再開
  void pauseResume() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      _controller.forward();
    }
  }

  // 次のフェーズに進む
  void nextPhase() {
    if (_currentPhaseIndex < _totalPhases - 1) {
      _currentPhaseIndex++;
    } else {
      _currentPhaseIndex = 0;
    }

    _controller.reset();
    _controller.forward();
    notifyListeners();
  }

  // 前のフェーズに戻る
  void previousPhase() {
    if (_currentPhaseIndex > 0) {
      _currentPhaseIndex--;
    } else {
      _currentPhaseIndex = _totalPhases - 1;
    }

    _controller.reset();
    _controller.forward();
    notifyListeners();
  }

  // 継続時間を更新
  void _updateDuration() {
    if (_controller.isAnimating) {
      _controller.stop();
      _controller.duration = Duration(seconds: _phaseSeconds);
      _controller.forward();
    } else {
      _controller.duration = Duration(seconds: _phaseSeconds);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
