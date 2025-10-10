import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/controllers/practice_timer_controller.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_info_card_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/practice_parameter_settings_widget.dart';
import 'package:soccer_app_flutter/shared/mixins/swipe_navigation_mixin.dart';
import 'package:soccer_app_flutter/shared/providers/practice_menu_provider.dart';
import 'package:soccer_app_flutter/pages/note_page/menu_form_page.dart';

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

  // 初期設定値
  static const int _initialPhaseSeconds = 10;
  static const int _initialTimerMinutes = 3;
  static const int _initialTimerSeconds = 0;

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
      _initialPhaseSeconds,
      _initialTimerMinutes,
      _initialTimerSeconds,
      this,
    );

    // コントローラーの変更を監視
    _controller.addListener(() {
      setState(() {});
    });
  }

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
              if (widget.menu.type == '自由帳')
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('編集'),
                  onTap: () {
                    Navigator.pop(context);
                    _editMenu();
                  },
                ),
              // 削除オプション（自由帳のみ）
              if (widget.menu.type == '自由帳')
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('削除', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete();
                  },
                ),
              // 既存メニューの場合は編集・削除不可のメッセージ
              if (widget.menu.type != '自由帳')
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '既存メニューは編集・削除できません',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              // キャンセル
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('キャンセル'),
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
          title: const Text('メニューの削除'),
          content: Text('「${widget.menu.name}」を削除しますか？\nこの操作は取り消せません．'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMenu();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('「${widget.menu.name}」を削除しました')));
        // 前の画面に戻る
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
      }
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
            tooltip: 'メニュー',
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          // スワイプで戻る機能（SwipeNavigationMixinから提供）
          onHorizontalDragEnd:
              (details) => handleSwipeNavigation(details, context),
          child: Column(
            children: [
              // 上部：メニューリストの内容を表示
              MenuInfoCardWidget(menu: widget.menu),

              // 中部：空白エリア
              const Expanded(child: SizedBox()),

              // 下部：パラメータ設定エリア
              PracticeParameterSettingsWidget(controller: _controller),
            ],
          ),
        ),
      ),
    );
  }
}
