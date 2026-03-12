import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/features/platform_channels/provisioning.dart';

/// プロビジョニングの進捗状態を表す列挙型
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
    orElse: () => ProvisioningStep.connecting,
  );
}

/// プロビジョニング進捗ダイアログ
///
/// BLEデバイスのプロビジョニング進捗をステップ表示付きプログレスバーで表示します．
///
/// ### 使用例:
/// ```dart
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   builder: (context) => ProvisioningProgressDialog(
///     deviceName: 'My Device',
///     deviceUuid: 'xxxx-xxxx-xxxx',
///   ),
/// );
/// ```
class ProvisioningProgressDialog extends StatefulWidget {
  final String deviceName;
  final String deviceUuid;

  const ProvisioningProgressDialog({
    super.key,
    required this.deviceName,
    required this.deviceUuid,
  });

  @override
  State<ProvisioningProgressDialog> createState() =>
      _ProvisioningProgressDialogState();
}

class _ProvisioningProgressDialogState
    extends State<ProvisioningProgressDialog> {
  final Provisioning _provisioning = Provisioning();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  ProvisioningStep _currentStep = ProvisioningStep.connecting;
  ProvisioningStep _lastStepBeforeError = ProvisioningStep.connecting;
  String _statusMessage = 'プロビジョニングを開始しています...';

  bool get _isCompleted => _currentStep == ProvisioningStep.complete;
  bool get _hasError => _currentStep == ProvisioningStep.error;

  // 全ステップ（エラーを除く）
  static const List<ProvisioningStep> _allSteps = [
    ProvisioningStep.connecting,
    ProvisioningStep.discovering,
    ProvisioningStep.identifying,
    ProvisioningStep.provisioning,
    ProvisioningStep.complete,
  ];

  @override
  void initState() {
    super.initState();
    _startProvisioning();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _startProvisioning() async {
    try {
      // プロビジョニング開始
      final response = await _provisioning.startProvisioning(widget.deviceUuid);

      if (!response['isSuccess']) {
        if (!mounted) return;
        setState(() {
          _currentStep = ProvisioningStep.error;
          _statusMessage = 'エラー: ${response['message']}';
        });
        return;
      }

      // プロビジョニングストリームを購読
      _subscription = _provisioning.provisioningStream.listen(
        (data) {
          if (!mounted) return;

          final status = data['status'] as String? ?? 'unknown';
          final message = data['message'] as String? ?? '';

          final step = ProvisioningStep.fromStatus(status);
          setState(() {
            if (step != ProvisioningStep.error) {
              _lastStepBeforeError = step;
            }
            _currentStep = step;
            _statusMessage = message;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _currentStep = ProvisioningStep.error;
            _statusMessage = 'エラーが発生しました: $error';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentStep = ProvisioningStep.error;
        _statusMessage = '予期しないエラー: $e';
      });
    }
  }

  /// 現在の進捗率を計算（0.0 ~ 1.0）
  double get _progressValue {
    if (_isCompleted) return 1.0;

    final displayStep = _hasError ? _lastStepBeforeError : _currentStep;
    final currentIndex = displayStep.stepIndex;
    if (currentIndex < 0) return 0.0;

    return (currentIndex + 1) / _allSteps.length;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isCompleted || _hasError,
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
        _hasError ? Colors.red : Colors.blue,
      ),
      minHeight: 8,
    );
  }

  /// ステップインジケーター
  Widget _buildStepIndicators() {
    // エラー時はエラー前のステップを基準にする
    final displayStep = _hasError ? _lastStepBeforeError : _currentStep;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          _allSteps.map((step) {
            final isActive = step.stepIndex <= displayStep.stepIndex;
            final isCurrent = step == displayStep;
            // エラー時、エラーが起きたステップを赤で表示
            final isErrorStep = _hasError && isCurrent;
            final displayColor = isErrorStep ? Colors.red : step.color;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isActive || isCurrent
                              ? displayColor.withValues(alpha: 0.2)
                              : Colors.grey[300],
                      border: Border.all(
                        color:
                            isActive || isCurrent ? displayColor : Colors.grey,
                        width: isCurrent ? 3 : 2,
                      ),
                    ),
                    child: Icon(
                      isErrorStep ? Icons.error : step.icon,
                      color: isActive || isCurrent ? displayColor : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isActive || isCurrent ? Colors.black : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  /// ステータスメッセージ（エラー / 完了 / 進行中）
  Widget _buildStatusMessage() {
    if (_hasError) {
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

    if (_isCompleted) {
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

  /// アクションボタン（完了/閉じる）
  Widget _buildActionButton() {
    if (!_isCompleted && !_hasError) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasError ? Colors.red : Colors.blue,
          foregroundColor: Colors.white,
        ),
        child: Text(_hasError ? '閉じる' : '完了'),
      ),
    );
  }
}
