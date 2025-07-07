import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/controllers/practice_timer_controller.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_info_card.dart';
import 'package:soccer_app_flutter/shared/widgets/practice_parameter_settings.dart';
import 'package:soccer_app_flutter/shared/mixins/swipe_navigation_mixin.dart';

// 練習メニューの詳細ページ
class PracticeDetailPage extends StatefulWidget {
  final PracticeMenu menu;

  const PracticeDetailPage({super.key, required this.menu});

  @override
  State<PracticeDetailPage> createState() => _PracticeDetailPageState();
}

class _PracticeDetailPageState extends State<PracticeDetailPage>
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.menu.name),
      ),
      body: GestureDetector(
        // スワイプで戻る機能（SwipeNavigationMixinから提供）
        onHorizontalDragEnd: (details) => handleSwipeNavigation(details, context),
        child: Column(
          children: [
            // 上部：メニューリストの内容を表示
            MenuInfoCard(menu: widget.menu),

            // 中部：空白エリア
            const Expanded(child: SizedBox()),

            // 下部：パラメータ設定エリア
            PracticeParameterSettings(controller: _controller),
          ],
        ),
      ),
    );
  }
}
