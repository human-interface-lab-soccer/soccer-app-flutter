import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/controllers/practice_timer_controller.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_info_card_widget.dart';
import 'package:soccer_app_flutter/shared/widgets/practice_parameter_settings_widget.dart';
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
      body: SafeArea(
        child: Stack( 
          children: [
             // 背景：メニュー情報と空白エリア
            GestureDetector(
            // スワイプで戻る機能（SwipeNavigationMixinから提供）
              onHorizontalDragEnd:
                  (details) => handleSwipeNavigation(details, context),
              child: SingleChildScrollView( // ← Column をスクロール可能にする！   
                padding: const EdgeInsets.only(bottom: 160), 
                child: Column(
                  children: [
                    // 上部：メニューリストの内容を表示
                    MenuInfoCardWidget(menu: widget.menu),

                    // 中部：空白エリア
                    const SizedBox(height: 300),
                  ],
                ),
              ),
            ), 
        
            // 下部：パラメータ設定エリア
            DraggableScrollableSheet(
              initialChildSize: 0.2, // ← 初期表示高さ（画面の20%）
              minChildSize: 0.1, // ← 最小（格納状態）
              maxChildSize: 0.8, // ← 最大（全開状態）
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
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
                      ), 

                      // スクロール可能なパラメータ設定ウィジェット
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController, // ← スクロール連携
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child:
                              PracticeParameterSettingsWidget(controller: _controller),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ), 
          ],
        ),
      ),
    );
  }
}
