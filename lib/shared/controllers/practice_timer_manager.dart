import 'package:flutter/material.dart';

// 練習タイマーを管理
class TimerManager with ChangeNotifier {
  int _minutes = 3;
  int _seconds = 0;
  late int _totalSeconds;
  late int _currentSeconds;
  late AnimationController _controller;
  late Animation<double> _animation;

  // ゲッター
  int get minutes => _minutes;
  int get seconds => _seconds;
  int get totalSeconds => _totalSeconds;
  int get currentSeconds => _currentSeconds;
  Animation<double> get animation => _animation;

  // 初期化
  void initialize(AnimationController controller) {
    _controller = controller;
    _totalSeconds = _minutes * 60 + _seconds;
    _currentSeconds = _totalSeconds;

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.addListener(() {
      _currentSeconds = (_totalSeconds * (1.0 - _controller.value)).round();
      notifyListeners();
    });
  }

  // タイマー時間を更新
  void updateTime(int minutes, int seconds) {
    _minutes = minutes;
    _seconds = seconds;
    _updateDuration();
    notifyListeners();
  }

  // タイマー開始
  void start() {
    _currentSeconds = _totalSeconds;
    _controller.reset();
    _controller.forward();
  }

  // タイマー停止
  void stop() {
    _controller.stop();
    _controller.reset();
    _currentSeconds = _totalSeconds;
  }

  // 一時停止・再開
  void pauseResume() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      _controller.forward();
    }
  }

  // 完了チェック
  bool isCompleted() {
    return _controller.status == AnimationStatus.completed;
  }

  // 継続時間を更新
  void _updateDuration() {
    _totalSeconds = _minutes * 60 + _seconds;
    _currentSeconds = _totalSeconds;
    _controller.duration = Duration(seconds: _totalSeconds);
  }

  // 時間をフォーマット
  String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
