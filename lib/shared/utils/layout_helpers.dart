import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/themes/button_theme_extension.dart'; // ボタンテーマの拡張をインポート

class LayoutHelpers {
  /// ボタンエリアの高さを計算するヘルパーメソッド
  static double calculateButtonAreaHeight(
    BuildContext context,
    ButtonThemeExtension buttonTheme,
  ) {
    final mediaQuery = MediaQuery.of(context);

    // bottomContainerの下部パディング
    final bottomContainer = mediaQuery.padding.bottom;

    // ボタンエリアの構成要素の高さを計算
    final containerPadding = buttonTheme.contentPadding * 2; // 上下のパディング
    final circleButtonHeight = buttonTheme.circleButtonSize;
    final sectionSpacing = buttonTheme.sectionSpacing;
    final boxButtonHeight = buttonTheme.boxButtonHeight;

    return containerPadding +
        circleButtonHeight +
        sectionSpacing +
        boxButtonHeight +
        bottomContainer;
  }

  /// 固定コンテンツエリアの高さを計算するヘルパーメソッド
  static double calculateFixedContentHeight(
    BuildContext context,
    ButtonThemeExtension buttonTheme,
  ) {
    // テキストの高さを推定（実際の計算はより複雑になる場合があります）
    final textStyle = Theme.of(context).textTheme.headlineMedium;
    final fontSize = textStyle?.fontSize ?? 24.0; // デフォルト値

    // 固定コンテンツの構成要素
    final firstTextHeight = 16.0 * 1.5; // 推定高さ
    final firstSpacing = buttonTheme.sectionSpacing;
    final actionFeedbackHeight = fontSize * 1.5; // 推定高さ
    final secondSpacing = buttonTheme.sectionSpacing;

    return firstTextHeight +
        firstSpacing +
        actionFeedbackHeight +
        secondSpacing;
  }
}
