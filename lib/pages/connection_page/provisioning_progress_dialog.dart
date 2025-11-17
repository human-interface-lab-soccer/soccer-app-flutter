import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/features/platform_channels/provisioning.dart';

/// プロビジョニングの進捗状態を表す列挙型
enum ProvisioningStep {
  connecting,
  discovering,
  identifying,
  provisioning,
  complete,
  error;

  /// ステータス文字列から列挙型に変換
  static ProvisioningStep fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'connecting':
        return ProvisioningStep.connecting;
      case 'discovering':
        return ProvisioningStep.discovering;
      case 'identifying':
        return ProvisioningStep.identifying;
      case 'provisioning':
        return ProvisioningStep.provisioning;
      case 'complete':
        return ProvisioningStep.complete;
      case 'error':
        return ProvisioningStep.error;
      default:
        return ProvisioningStep.connecting;
    }
  }

  /// ステップのインデクスを取得（プログレスバー用）
  int get stepIndex {
    switch (this) {
      case ProvisioningStep.connecting:
        return 0;
      case ProvisioningStep.discovering:
        return 1;
      case ProvisioningStep.identifying:
        return 2;
      case ProvisioningStep.provisioning:
        return 3;
      case ProvisioningStep.complete:
        return 4;
      case ProvisioningStep.error:
        return -1;
    }
  }

  /// ステップの日本語名を取得
  String get displayName {
    switch (this) {
      case ProvisioningStep.connecting:
        return '接続中';
      case ProvisioningStep.discovering:
        return 'サービス検索中';
      case ProvisioningStep.identifying:
        return '識別中';
      case ProvisioningStep.provisioning:
        return 'プロビジョニング中';
      case ProvisioningStep.complete:
        return '完了';
      case ProvisioningStep.error:
        return 'エラー';
    }
  }

  ///ステップのアイコンを取得
  IconData get icon {
    switch (this) {
      case ProvisioningStep.connecting:
        return Icons.bluetooth;
      case ProvisioningStep.discovering:
        return Icons.bluetooth_searching;
      case ProvisioningStep.identifying:
        return Icons.search;
      case ProvisioningStep.provisioning:
        return Icons.settings;
      case ProvisioningStep.complete:
        return Icons.check_circle;
      case ProvisioningStep.error:
        return Icons.error;
    }
  }

  /// ステップの色を取得
  Color get color {
    switch (this) {
      case ProvisioningStep.complete:
        return Colors.green;
      case ProvisioningStep.error:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
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
  ProvisioningStep _currentStep = ProvisioningStep.connecting;
  String _statusMessage = 'プロビジョニングを開始しています...';
  bool _isCompleted = false;
  bool _hasError = false;

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

  Future<void> _startProvisioning() async {
    try {
      // プロビジョニング開始
      final response = await _provisioning.startProvisioning(widget.deviceUuid);

      if (!response['isSuccess']) {
        if (!mounted) return;
        setState(() {
          _currentStep = ProvisioningStep.error;
          _statusMessage = 'エラー: ${response['message']}';
          _hasError = true;
        });
        return;
      }

      // プロビジョニングストリームを購読
      _provisioning.provisioningStream.listen(
        (data) {
          if (!mounted) return;

          final status = data['status'] as String? ?? 'unknown';
          final message = data['message'] as String? ?? '';

          setState(() {
            _currentStep = ProvisioningStep.fromStatus(status);
            _statusMessage = message;

            if (_currentStep == ProvisioningStep.complete) {
              _isCompleted = true;
            } else if (_currentStep == ProvisioningStep.error) {
              _hasError = true;
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _currentStep = ProvisioningStep.error;
            _statusMessage = 'エラーが発生しました: $error';
            _hasError = true;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentStep = ProvisioningStep.error;
        _statusMessage = '予期しないエラー: $e';
        _hasError = true;
      });
    }
  }

  /// 現在の進捗率を計算（0.0 ~ 1.0）
  double get _progressValue {
    if (_hasError) return 0.0;
    if (_isCompleted) return 1.0;

    final currentIndex = _currentStep.stepIndex;
    if (currentIndex < 0) return 0.0;

    return (currentIndex + 1) / _allSteps.length;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル
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
            const SizedBox(height: 24),

            // プログレスバー
            LinearProgressIndicator(
              value: _progressValue,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _hasError ? Colors.red : Colors.blue,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 16),

            // 現在のステップインジケーター
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  _allSteps.map((step) {
                    final isActive = step.stepIndex <= _currentStep.stepIndex;
                    final isCurrent = step == _currentStep;

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
                                      ? step.color.withValues(alpha: 0.2)
                                      : Colors.grey[300],
                              border: Border.all(
                                color:
                                    isActive || isCurrent
                                        ? step.color
                                        : Colors.grey,
                                width: isCurrent ? 3 : 2,
                              ),
                            ),
                            child: Icon(
                              step.icon,
                              color:
                                  isActive || isCurrent
                                      ? step.color
                                      : Colors.grey,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isActive || isCurrent
                                      ? Colors.black
                                      : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),

            // エラー表示
            if (_hasError)
              Container(
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
              )
            else if (_isCompleted)
              // 完了表示
              Container(
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
              )
            else
              // 進行中のメッセージ
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // ボタン
            if (_isCompleted || _hasError)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasError ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_hasError ? '閉じる' : '完了'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
