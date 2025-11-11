import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_app_flutter/features/platform_channels/mesh_network.dart';
import 'package:soccer_app_flutter/shared/enums/led_color.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/controllers/practice_timer_controller.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_info_card_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/practice_parameter_settings_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/led_display_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/led_preview_widget.dart';
import 'package:soccer_app_flutter/shared/mixins/swipe_navigation_mixin.dart';
import 'package:soccer_app_flutter/shared/providers/practice_menu_provider.dart';
import 'package:soccer_app_flutter/pages/note_page/menu_form_page.dart';

// 定数定義
class PracticeDetailConstants {
  // 初期設定値
  static const int defaultPhaseSeconds = 10;
  static const int defaultTimerMinutes = 3;
  static const int defaultTimerSeconds = 0;

  // メニュータイプ
  static const String customMenuType = '自由帳';

  // メッセージ
  static const String editLabel = '編集';
  static const String deleteLabel = '削除';
  static const String cancelLabel = 'キャンセル';
  static const String menuLabel = 'メニュー';
  static const String deleteDialogTitle = 'メニューの削除';
  static const String cannotEditMessage = '既存メニューは編集・削除できません';

  // エラーメッセージのテンプレート
  static String deleteConfirmMessage(String menuName) =>
      '「$menuName」を削除しますか？\nこの操作は取り消せません．';
  static String deleteSuccessMessage(String menuName) => '「$menuName」を削除しました';
  static String deleteErrorMessage(String error) => '削除に失敗しました: $error';
}

// 練習メニューの詳細ページ
class PracticeDetailPage extends ConsumerStatefulWidget {
  final PracticeMenu menu;

  const PracticeDetailPage({super.key, required this.menu});

  @override
  ConsumerState<PracticeDetailPage> createState() => _PracticeDetailPageState();
}

class _PracticeDetailPageState extends ConsumerState<PracticeDetailPage>
    with TickerProviderStateMixin, SwipeNavigationMixin {
  late PracticeTimerController _controller;

  int previousPhaseIndex = -1;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// コントローラーの初期化処理
  void _initializeController() {
    _controller = PracticeTimerController();
    _controller.initialize(
      widget.menu.phaseCount,
      PracticeDetailConstants.defaultPhaseSeconds,
      PracticeDetailConstants.defaultTimerMinutes,
      PracticeDetailConstants.defaultTimerSeconds,
      this,
    );

    // コントローラーの変更を監視
    _controller.addListener(() {
      setState(() {
        int currentPhaseIndex = _controller.currentPhaseIndex;
        if (previousPhaseIndex != currentPhaseIndex) {
          previousPhaseIndex = currentPhaseIndex;
          _setNodeColors();
        }
      });
    });
  }

  /// 編集可能なメニューかどうかを判定
  bool get _isCustomMenu =>
      widget.menu.type == PracticeDetailConstants.customMenuType;

  /// メニューボタンを表示
  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 編集オプション（自由帳のみ）
              if (_isCustomMenu)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text(PracticeDetailConstants.editLabel),
                  onTap: () {
                    Navigator.pop(context);
                    _editMenu();
                  },
                ),
              // 削除オプション（自由帳のみ）
              if (_isCustomMenu)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    PracticeDetailConstants.deleteLabel,
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete();
                  },
                ),
              // 既存メニューの場合は編集・削除不可のメッセージ
              if (!_isCustomMenu)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    PracticeDetailConstants.cannotEditMessage,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              // キャンセル
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text(PracticeDetailConstants.cancelLabel),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// メニューの編集処理
  void _editMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuFormPage(existingMenu: widget.menu),
      ),
    );
  }

  /// 削除確認ダイアログを表示
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(PracticeDetailConstants.deleteDialogTitle),
          content: Text(
            PracticeDetailConstants.deleteConfirmMessage(widget.menu.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(PracticeDetailConstants.cancelLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMenu();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text(PracticeDetailConstants.deleteLabel),
            ),
          ],
        );
      },
    );
  }

  /// メニューの削除処理
  Future<void> _deleteMenu() async {
    try {
      // RiverpodのpracticeMenuProviderを使用して削除
      await ref.read(practiceMenuProvider.notifier).deleteMenu(widget.menu.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              PracticeDetailConstants.deleteSuccessMessage(widget.menu.name),
            ),
          ),
        );
        // 前の画面に戻る
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              PracticeDetailConstants.deleteErrorMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  /// mesh network の setNodeColors を呼び出すテスト用関数
  Future<void> _setNodeColors() async {
    var response = await MeshNetwork.setNodeColors(
      nodeColors: {
        for (int i = 0; i < widget.menu.ledCount; i++)
          i: LedColor.fromLabel(
            widget.menu.colorSettings[i][_controller.currentPhaseIndex],
          ),
      },
    );
    if (!response['isSuccess']) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('エラー'),
            content: Text('LEDの色設定に失敗しました: ${response['message']}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.menu.name),
        actions: [
          // メニューボタン（・・・）
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMenuOptions,
            tooltip: PracticeDetailConstants.menuLabel,
          ),
        ],
      ),
      body: SafeArea(
        child:
            _controller.isRunning ? _buildRunningLayout() : _buildIdleLayout(),
      ),
    );
  }

  /// 練習開始前のレイアウト（DraggableScrollableSheet使用）
  Widget _buildIdleLayout() {
    return GestureDetector(
      onHorizontalDragEnd: (details) => handleSwipeNavigation(details, context),
      child: Stack(
        children: [
          // 背景：メニュー情報とLEDプレビュー
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.1,
            ),
            child: Column(
              children: [
                // 上部：メニュー情報
                MenuInfoCardWidget(menu: widget.menu),
                // 中部：LEDプレビュー
                LedPreviewWidget(menu: widget.menu),
              ],
            ),
          ),

          // 下部：ドラッグ可能なパラメータ設定エリア
          _buildScrollableContent(),
        ],
      ),
    );
  }

  /// 下部：ドラッグ可能なパラメータ設定エリア
  Widget _buildScrollableContent() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5, // 初期表示高さ（画面の50%）
      minChildSize: 0.1, // 最小（格納状態）
      maxChildSize: 0.8, // 最大（全開状態）
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              // つまみバー
              _buildDragHandle(),

              // スクロール可能なパラメータ設定ウィジェット
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PracticeParameterSettingsWidget(
                      controller: _controller,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// つまみバーの構築
  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  /// 練習実行中のレイアウト（固定レイアウト）
  Widget _buildRunningLayout() {
    return GestureDetector(
      onHorizontalDragEnd: (details) => handleSwipeNavigation(details, context),
      child: Column(
        children: [
          // スクロール可能な上部エリア
          Expanded(
            child: SingleChildScrollView(
              child: LedDisplayWidget(
                menu: widget.menu,
                currentPhaseIndex: _controller.currentPhaseIndex,
              ),
            ),
          ),

          // 下部：パラメータ設定エリア（固定）
          PracticeParameterSettingsWidget(controller: _controller),
        ],
      ),
    );
  }
}
