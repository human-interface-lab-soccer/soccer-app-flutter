import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/controllers/practice_timer_manager.dart';
import 'package:soccer_app_flutter/shared/controllers/practice_phase_manager.dart';

class PracticeTimerController with ChangeNotifier {
  late TimerManager _timerManager;
  late PhaseManager _phaseManager;
  bool _isRunning = false;
  bool _isPaused = false;

  // ゲッター
  TimerManager get timerManager => _timerManager;
  PhaseManager get phaseManager => _phaseManager;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;

  // 初期化
  void initialize(
    int totalPhases,
    int phaseSeconds,
    int timerMinutes,
    int timerSeconds,
    TickerProvider vsync,
  ) {
    // アニメーションコントローラーの作成
    final timerController = AnimationController(
      vsync: vsync,
      duration: Duration(seconds: timerMinutes * 60 + timerSeconds),
    );
    final meterController = AnimationController(
      vsync: vsync,
      duration: Duration(seconds: phaseSeconds),
    );

    _timerManager = TimerManager();
    _phaseManager = PhaseManager();

    _timerManager.initialize(timerController);
    _phaseManager.initialize(totalPhases, meterController);

    // 各マネージャーの変更を監視
    _timerManager.addListener(() => notifyListeners());
    _phaseManager.addListener(() => notifyListeners());

    // タイマー完了時の処理
    timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        stopPractice();
      }
    });
  }

  // 練習開始
  void startPractice() {
    _isRunning = true;
    _isPaused = false;
    _timerManager.start();
    _phaseManager.startPhase();
    notifyListeners();
  }

  // 練習停止
  void stopPractice() {
    _isRunning = false;
    _isPaused = false;
    _timerManager.stop();
    _phaseManager.stopPhase();
    notifyListeners();
  }

  // 一時停止・再開
  void pauseResumePractice() {
    if (_isRunning) {
      _isPaused = !_isPaused;
      _timerManager.pauseResume();
      _phaseManager.pauseResume();
      notifyListeners();
    }
  }

  // 実行中かチェック
  bool isActive() {
    return _isRunning && !_isPaused;
  }

  // フェーズ時間を更新
  void updatePhaseSeconds(int seconds) {
    _phaseManager.updatePhaseSeconds(seconds);
  }

  // タイマー時間を更新
  void updateTimerTime(int minutes, int seconds) {
    _timerManager.updateTime(minutes, seconds);
  }

  // 次のフェーズに進む
  void nextPhase() {
    if (isActive()) {
      _phaseManager.nextPhase();
    }
  }

  // 前のフェーズに戻る
  void previousPhase() {
    if (isActive()) {
      _phaseManager.previousPhase();
    }
  }

  // 便利なゲッター（互換性のため）
  int get phaseSeconds => _phaseManager.phaseSeconds;
  int get timerMinutes => _timerManager.minutes;
  int get timerSeconds => _timerManager.seconds;
  int get currentPhaseIndex => _phaseManager.currentPhaseIndex;
  int get totalPhases => _phaseManager.totalPhases;
  int get currentTimerSeconds => _timerManager.currentSeconds;
  int get totalTimerSeconds => _timerManager.totalSeconds;
  Animation<double> get meterAnimation => _phaseManager.animation;
  Animation<double> get timerAnimation => _timerManager.animation;

  // 時間をフォーマット
  String formatTime(int totalSeconds) {
    return _timerManager.formatTime(totalSeconds);
  }

  @override
  void dispose() {
    _timerManager.dispose();
    _phaseManager.dispose();
    super.dispose();
  }
}
