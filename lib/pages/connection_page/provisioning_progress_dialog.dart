import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/features/platform_channels/provisioning.dart';
import 'package:soccer_app_flutter/features/platform_channels/mesh_network.dart';

/// プロビジョニングおよびセットアップウィザードの各ステップを表す列挙型
enum WizardStep {
  provisioning(0, 'Provisioning', Icons.bluetooth_searching, Colors.blue),
  configuration(1, 'Configuration', Icons.settings, Colors.blue),
  subscription(2, 'Subscription', Icons.notifications_active, Colors.blue),
  publication(3, 'Publication', Icons.publish, Colors.blue);

  const WizardStep(this.stepIndex, this.displayName, this.icon, this.color);

  final int stepIndex;
  final String displayName;
  final IconData icon;
  final Color color;
}

/// ウィザード内の各ステップの状態を表す列挙型
enum StepStatus { idle, waitingUserConfirmation, running, success, failed }

/// プロビジョニングの進捗状態を表す列挙型（内部サブステップ用）
enum ProvisioningStep {
  connecting(0, '接続中', Icons.bluetooth, Colors.blue),
  discovering(1, 'サービス検索中', Icons.bluetooth_searching, Colors.blue),
  identifying(2, '識別中', Icons.search, Colors.blue),
  provisioning(3, 'プロビジョニング中', Icons.settings, Colors.blue),
  complete(4, '完了', Icons.check_circle, Colors.green),
  error(-1, 'エラー', Icons.error, Colors.red);

  const ProvisioningStep(
    this.stepIndex,
    this.displayName,
    this.icon,
    this.color,
  );

  final int stepIndex;
  final String displayName;
  final IconData icon;
  final Color color;

  /// ステータス文字列から列挙型に変換
  static ProvisioningStep fromStatus(String status) => values.firstWhere(
    (e) => e.name == status.toLowerCase(),
    orElse: () => ProvisioningStep.error,
  );
}

/// プロビジョニング進捗ダイアログ (セットアップウィザード)
///
/// BLEデバイスのプロビジョニングから各種設定（Configuration, Subscription, Publication）までを
/// 順番に実行するウィザード形式のフローを表示します．
class ProvisioningProgressDialog extends StatefulWidget {
  final String deviceName;
  final String deviceUuid;
  final bool isMockDevice;

  const ProvisioningProgressDialog({
    super.key,
    required this.deviceName,
    required this.deviceUuid,
    this.isMockDevice = false,
  });

  @override
  State<ProvisioningProgressDialog> createState() =>
      _ProvisioningProgressDialogState();
}

class _ProvisioningProgressDialogState
    extends State<ProvisioningProgressDialog> {
  final Provisioning _provisioning = Provisioning();
  StreamSubscription<Map<String, dynamic>>? _subscription; // provisioningStream
  StreamSubscription<Map<String, dynamic>>?
  _meshSubscription; // meshNetworkStream
  Timer? _timeoutTimer;

  bool _isDebugMode = false;
  WizardStep _currentWizardStep = WizardStep.provisioning;
  StepStatus _currentStepStatus = StepStatus.running;
  int? _unicastAddress;

  // Provisioningサブステップ用
  ProvisioningStep _currentStep = ProvisioningStep.connecting;
  String _statusMessage = 'プロビジョニングを開始しています...';

  @override
  void initState() {
    super.initState();
    _isDebugMode = widget.isMockDevice;

    // イベントストリームはダイアログの初期化時に一度だけ購読し，disposeまで維持する
    _meshSubscription = MeshNetwork.meshNetworkStream.listen(
      _handleMeshNetworkEvent,
      onError: _handleMeshNetworkError,
    );

    // 最初のステップ (Provisioning) は自動的に実行を開始する
    _triggerStepAction();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _meshSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  /// メッシュネットワークからのイベント通知を処理するハンドラ
  void _handleMeshNetworkEvent(Map<String, dynamic> event) {
    if (!mounted) return;

    final eventType = event['eventType'] as String?;
    final status = event['status'] as String?;
    final message = event['message'] as String? ?? '';
    final meshState = event['meshState'] as String?;

    debugPrint(
      '[Wizard Stream] Received eventType: $eventType, status: $status, message: $message, meshState: $meshState',
    );

    if (eventType == 'meshStateChanged' && meshState != null) {
      setState(() {
        switch (meshState) {
          case 'PROVISIONING':
            _currentWizardStep = WizardStep.provisioning;
            _currentStepStatus = StepStatus.running;
            _statusMessage = 'プロビジョニング中...';
            break;
          case 'PROVISIONING_COMPLETE':
            _currentWizardStep = WizardStep.provisioning;
            _currentStepStatus = StepStatus.success;
            _statusMessage = 'プロビジョニング完了';
            break;
          case 'WAIT_PROXY_CONNECTION':
            _currentWizardStep = WizardStep.configuration;
            _currentStepStatus = StepStatus.running;
            _statusMessage = 'Proxy接続を待っています...';
            break;
          case 'PROXY_CONNECTED':
            _currentWizardStep = WizardStep.configuration;
            _currentStepStatus = StepStatus.running;
            _statusMessage = '接続完了';
            break;
          case 'WAIT_COMPOSITION':
            _currentWizardStep = WizardStep.configuration;
            _currentStepStatus = StepStatus.running;
            _statusMessage = 'Composition Dataを取得中...';
            break;
          case 'CONFIGURING':
            _currentWizardStep = WizardStep.configuration;
            _currentStepStatus = StepStatus.running;
            _statusMessage = '設定中...';
            break;
          case 'COMPLETE':
            _currentWizardStep = WizardStep.configuration;
            _currentStepStatus = StepStatus.success;
            _statusMessage = 'Configuration完了';
            break;
          case 'SUBSCRIPTION':
            _currentWizardStep = WizardStep.subscription;
            _currentStepStatus = StepStatus.running;
            _statusMessage = 'Subscription設定中...';
            break;
          case 'PUBLICATION':
            _currentWizardStep = WizardStep.publication;
            _currentStepStatus = StepStatus.running;
            _statusMessage = 'Publication設定中...';
            break;
        }
      });
      return;
    }

    if (_currentStepStatus != StepStatus.running) return;

    if (_currentWizardStep == WizardStep.configuration) {
      if (eventType == 'configuration') {
        if (status == 'success') {
          _handleStepSuccess('Configuration完了');
        } else if (status == 'error') {
          _handleStepFailure('Configuration失敗: $message');
        }
      }
    } else if (_currentWizardStep == WizardStep.subscription) {
      if (eventType == 'subscription') {
        if (status == 'success') {
          _handleStepSuccess('Subscription設定完了');
        } else if (status == 'error') {
          _handleStepFailure('Subscription設定失敗: $message');
        }
      }
    } else if (_currentWizardStep == WizardStep.publication) {
      if (eventType == 'publication') {
        if (status == 'success') {
          _handleStepSuccess('Publication設定完了');
        } else if (status == 'error') {
          _handleStepFailure('Publication設定失敗: $message');
        }
      }
    }
  }

  /// メッシュネットワークエラーハンドラ
  void _handleMeshNetworkError(dynamic error) {
    if (!mounted) return;
    if (_currentStepStatus == StepStatus.running) {
      _handleStepFailure('通信エラーが発生しました: $error');
    }
  }

  /// 各ステップ成功時の状態更新
  void _handleStepSuccess(String successMessage) {
    _timeoutTimer?.cancel();
    setState(() {
      _currentStepStatus = StepStatus.success;
      _statusMessage = successMessage;
    });
    debugPrint('[Wizard] Step $_currentWizardStep succeeded.');
  }

  /// 各ステップ失敗（エラー）時の状態更新
  void _handleStepFailure(String errorMessage) {
    _timeoutTimer?.cancel();
    setState(() {
      _currentStepStatus = StepStatus.failed;
      _statusMessage = errorMessage;
    });
    debugPrint('[Wizard] Step $_currentWizardStep failed: $errorMessage');
  }

  // /// タイムアウトタイマーの起動（15秒）
  // void _startTimeoutTimer() {
  //   _timeoutTimer?.cancel();
  //   if (_isDebugMode) return; // デバッグモードではタイムアウトさせない

  //   _timeoutTimer = Timer(const Duration(seconds: 15), () {
  //     if (!mounted) return;
  //     debugPrint('[Wizard] Step $_currentWizardStep timed out.');
  //     setState(() {
  //       _currentStepStatus = StepStatus.failed;
  //       _statusMessage = 'タイムアウトしました。もう一度お試しください。';
  //     });
  //   });
  // }

  /// 各ステップのアクションを起動するメソッド
  Future<void> _triggerStepAction() async {
    setState(() {
      _currentStepStatus = StepStatus.running;
    });

    debugPrint(
      '[Wizard] Running step: $_currentWizardStep (DebugMode: $_isDebugMode)',
    );

    // デバッグモード（疑似実行）
    if (_isDebugMode) {
      switch (_currentWizardStep) {
        case WizardStep.provisioning:
          _startProvisioningDebug();
          break;
        case WizardStep.configuration:
          _statusMessage = 'Configuration実行中... (Debug)';
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) _handleStepSuccess('Configuration完了 (Debug)');
          break;
        case WizardStep.subscription:
          _statusMessage = 'Subscription設定実行中... (Debug)';
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) _handleStepSuccess('Subscription設定完了 (Debug)');
          break;
        case WizardStep.publication:
          _statusMessage = 'Publication設定実行中... (Debug)';
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) _handleStepSuccess('Publication設定完了 (Debug)');
          break;
      }
      return;
    }

    // 本番環境フローでは最初のProvisioningのみFlutter側からトリガーする
    if (_currentWizardStep == WizardStep.provisioning) {
      _statusMessage = '接続中...';
      _startProvisioning();
    }
  }

  /// 本番用のプロビジョニング実行メソッド
  Future<void> _startProvisioning() async {
    try {
      // 以前のプロビジョニング購読があれば解除
      await _subscription?.cancel();

      final response = await _provisioning.startProvisioning(widget.deviceUuid);

      if (!response['isSuccess']) {
        if (!mounted) return;
        _handleStepFailure('プロビジョニング開始失敗: ${response['message']}');
        return;
      }

      _subscription = _provisioning.provisioningStream.listen(
        (data) {
          if (!mounted) return;

          final status = data['status'] as String? ?? 'unknown';
          final message = data['message'] as String? ?? '';

          final step = ProvisioningStep.fromStatus(status);
          setState(() {
            _currentStep = step;
            _statusMessage = message;

            if (step == ProvisioningStep.complete) {
              _unicastAddress = data['unicastAddress'] as int?;
              _currentStepStatus = StepStatus.success;
              _statusMessage = 'プロビジョニングが完了しました！';
              debugPrint(
                '[Wizard] Provisioning complete. UnicastAddress: $_unicastAddress',
              );
            } else if (step == ProvisioningStep.error) {
              _currentStepStatus = StepStatus.failed;
              _statusMessage = 'プロビジョニング失敗: $message';
              debugPrint('[Wizard] Provisioning failed: $message');
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          _handleStepFailure('プロビジョニングエラー: $error');
        },
      );
    } catch (e) {
      _handleStepFailure('プロビジョニング中に例外が発生しました: $e');
    }
  }

  /// デバッグ用のプロビジョニング擬似実行メソッド
  Future<void> _startProvisioningDebug() async {
    const steps = [
      ('connecting', '接続中...'),
      ('discovering', 'サービス検索中...'),
      ('identifying', '識別中...'),
      ('provisioning', 'プロビジョニング中...'),
      ('complete', 'プロビジョニング完了！'),
    ];

    for (final (status, message) in steps) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      final step = ProvisioningStep.fromStatus(status);
      setState(() {
        _currentStep = step;
        _statusMessage = message;

        if (step == ProvisioningStep.complete) {
          _unicastAddress = 99; // デバッグ用の疑似ユニキャストアドレス
          _currentStepStatus = StepStatus.success;
          _statusMessage = 'プロビジョニングが完了しました！ (Debug)';
          debugPrint(
            '[Wizard Debug] Provisioning complete. Mock Unicast Address: 99',
          );
        }
      });
    }
  }

  // /// NEXTボタンまたは完了ボタンが押下されたときの処理
  // void _handleNextStep() {
  //   if (_currentWizardStep == WizardStep.publication &&
  //       _currentStepStatus == StepStatus.success) {
  //     // 最終ステップ完了時はダイアログを閉じる
  //     Navigator.of(context).pop();
  //     return;
  //   }

  //   final nextIndex = _currentWizardStep.stepIndex + 1;
  //   if (nextIndex < WizardStep.values.length) {
  //     setState(() {
  //       _currentWizardStep = WizardStep.values[nextIndex];
  //       _currentStepStatus = StepStatus.waitingUserConfirmation;

  //       // 次のステップの初期表示メッセージを設定
  //       switch (_currentWizardStep) {
  //         case WizardStep.configuration:
  //           _statusMessage = 'Configurationを開始しますか？';
  //           break;
  //         case WizardStep.subscription:
  //           _statusMessage = 'Set Subscriptionを開始しますか？';
  //           break;
  //         case WizardStep.publication:
  //           _statusMessage = 'Set Publicationを開始しますか？';
  //           break;
  //         default:
  //           break;
  //       }
  //     });
  //     debugPrint(
  //       '[Wizard] Transitioned to $_currentWizardStep (waitingUserConfirmation)',
  //     );
  //   }
  // }

  /// ウィザード全体の進捗率の計算 (0.0 ~ 1.0)
  double get _progressValue {
    if (_currentWizardStep == WizardStep.publication &&
        _currentStepStatus == StepStatus.success) {
      return 1.0;
    }

    final currentStepIndex = _currentWizardStep.stepIndex;
    double stepBaseProgress = currentStepIndex / WizardStep.values.length;

    double statusProgress = 0.0;
    if (_currentStepStatus == StepStatus.success) {
      statusProgress = 1.0 / WizardStep.values.length;
    } else if (_currentStepStatus == StepStatus.running) {
      if (_currentWizardStep == WizardStep.provisioning) {
        final subStepIndex = _currentStep.stepIndex;
        if (subStepIndex >= 0) {
          statusProgress =
              (subStepIndex + 1) /
              (ProvisioningStep.values.length - 1) /
              WizardStep.values.length;
        }
      } else {
        statusProgress = 0.5 / WizardStep.values.length;
      }
    }

    return (stepBaseProgress + statusProgress).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isFinished =
        _currentWizardStep == WizardStep.publication &&
        _currentStepStatus == StepStatus.success;
    final isFailed = _currentStepStatus == StepStatus.failed;

    return PopScope(
      canPop: isFinished || isFailed,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildProgressBar(),
              const SizedBox(height: 16),
              _buildStepIndicators(),
              const SizedBox(height: 24),
              _buildStatusMessage(),
              const SizedBox(height: 24),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダー（デバイス名・UUID）
  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          widget.deviceName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'UUID: ${widget.deviceUuid}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// プログレスバー
  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: _progressValue,
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(
        _currentStepStatus == StepStatus.failed ? Colors.red : Colors.blue,
      ),
      minHeight: 8,
    );
  }

  /// ウィザード各ステップのインジケーター表示
  Widget _buildStepIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          WizardStep.values.map((step) {
            final isCompleted =
                step.stepIndex < _currentWizardStep.stepIndex ||
                (_currentWizardStep == step &&
                    _currentStepStatus == StepStatus.success);
            final isActive = _currentWizardStep == step;
            final isFailed =
                _currentWizardStep == step &&
                _currentStepStatus == StepStatus.failed;

            final displayColor =
                isFailed
                    ? Colors.red
                    : isCompleted
                    ? Colors.green
                    : isActive
                    ? Colors.blue
                    : Colors.grey;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isActive || isCompleted
                              ? displayColor.withValues(alpha: 0.2)
                              : Colors.grey[300],
                      border: Border.all(
                        color: displayColor,
                        width: isActive ? 3 : 2,
                      ),
                    ),
                    child: Icon(
                      isFailed
                          ? Icons.error
                          : isCompleted
                          ? Icons.check
                          : step.icon,
                      color: displayColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color:
                          isActive || isCompleted ? Colors.black : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  /// ステータスメッセージ表示エリア
  Widget _buildStatusMessage() {
    if (_currentStepStatus == StepStatus.failed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentStepStatus == StepStatus.success) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusMessage,
                style: const TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentStepStatus == StepStatus.running) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_statusMessage, style: const TextStyle(fontSize: 14)),
          ),
        ],
      );
    }

    // waitingUserConfirmation
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: const TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// アクションボタン表示
  Widget _buildActionButton() {
    final isFinished =
        _currentWizardStep == WizardStep.publication &&
        _currentStepStatus == StepStatus.success;
    final isFailed = _currentStepStatus == StepStatus.failed;

    if (isFinished) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('完了'),
        ),
      );
    }

    if (isFailed) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentWizardStep = WizardStep.provisioning;
                  _currentStep = ProvisioningStep.connecting;
                  _statusMessage = 'プロビジョニングを開始しています...';
                });
                _triggerStepAction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
