import 'package:flutter/material.dart';

/// スワイプナビゲーション機能を提供するMixin
mixin SwipeNavigationMixin {
  /// スワイプナビゲーションのハンドリング
  void handleSwipeNavigation(DragEndDetails details, BuildContext context) {
    const double swipeThreshold = 300.0;

    if (details.velocity.pixelsPerSecond.dx > swipeThreshold) {
      // 右にスワイプした場合，前のページに戻る
      Navigator.of(context).pop();
    }
  }
}
