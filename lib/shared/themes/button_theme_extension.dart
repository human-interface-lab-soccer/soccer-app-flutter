import 'package:flutter/material.dart';

class ButtonThemeExtension extends ThemeExtension<ButtonThemeExtension> {
  final double circleButtonSize; // 円形ボタンのデフォルトサイズ
  final double boxButtonMinWidth; // 四角いボタンのデフォルト最小幅
  final double boxButtonHeight; // 四角いボタンのデフォルト高さ
  final double buttonSpacing; // ボタン同士の間隔
  final double sectionSpacing; // ボタンとボタンの間のスペース
  final double contentPadding; // コンテンツの内側余白

  const ButtonThemeExtension({
    required this.circleButtonSize,
    required this.boxButtonMinWidth,
    required this.boxButtonHeight,
    required this.buttonSpacing,
    required this.sectionSpacing,
    required this.contentPadding,
  });

  @override
  // コピー用のメソッド（一部の値だけ変更した新しいテーマを簡単に作れる）
  ButtonThemeExtension copyWith({
    double? circleButtonSize,
    double? boxButtonMinWidth,
    double? boxButtonHeight,
    double? buttonSpacing,
    double? sectionSpacing,
    double? contentPadding,
  }) {
    return ButtonThemeExtension(
      circleButtonSize: circleButtonSize ?? this.circleButtonSize,
      boxButtonMinWidth: boxButtonMinWidth ?? this.boxButtonMinWidth,
      boxButtonHeight: boxButtonHeight ?? this.boxButtonHeight,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      contentPadding: contentPadding ?? this.contentPadding,
    );
  }

  @override
  // 他のテーマと補間して滑らかな変化を作るメソッド
  // 「Aテーマ→Bテーマ」へ一瞬で切り替えるのではなく、
  // lerpで“間の値”を計算しながら、なめらかに変化させるために使われるらしい
  ButtonThemeExtension lerp(ButtonThemeExtension? other, double t) {
    if (other == null) return this;
    return ButtonThemeExtension(
      circleButtonSize:
          (circleButtonSize * (1 - t) + other.circleButtonSize * t),
      boxButtonMinWidth:
          (boxButtonMinWidth * (1 - t) + other.boxButtonMinWidth * t),
      boxButtonHeight: (boxButtonHeight * (1 - t) + other.boxButtonHeight * t),
      buttonSpacing: (buttonSpacing * (1 - t) + other.buttonSpacing * t),
      sectionSpacing: (sectionSpacing * (1 - t) + other.sectionSpacing * t),
      contentPadding: (contentPadding * (1 - t) + other.contentPadding * t),
    );
  }

  // 画面サイズに基づいてスケーリングされた値を返す
  ButtonThemeExtension scaleForScreenSize(Size screenSize) {
    // 基準サイズ（デザイン時の想定サイズ）
    const baseWidth = 400.0;
    const baseHeight = 800.0;

    // スケールファクターを計算（最小0.7倍，最大1.3倍に制限）
    final widthScale = (screenSize.width / baseWidth).clamp(0.7, 1.3);
    final heightScale = (screenSize.height / baseHeight).clamp(0.7, 1.3);
    final scale = (widthScale + heightScale) / 2;

    return ButtonThemeExtension(
      circleButtonSize: circleButtonSize * scale,
      boxButtonMinWidth: boxButtonMinWidth * scale,
      boxButtonHeight: boxButtonHeight * scale,
      buttonSpacing: buttonSpacing * scale,
      sectionSpacing: sectionSpacing * scale,
      contentPadding: contentPadding * scale,
    );
  }
}
