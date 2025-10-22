/// LED表示の設定クラス
class LedDisplayConfig {
  final double size;
  final double spacing;
  final double borderWidth;
  final double fontSize;
  final double shadowSpreadRadius;
  final double shadowBlurRadius;
  final double shadowAlpha;

  const LedDisplayConfig({
    required this.size,
    required this.spacing,
    required this.borderWidth,
    required this.fontSize,
    required this.shadowSpreadRadius,
    required this.shadowBlurRadius,
    required this.shadowAlpha,
  });

  /// 通常サイズの設定（練習中）
  static const LedDisplayConfig normal = LedDisplayConfig(
    size: 60,
    spacing: 12,
    borderWidth: 3,
    fontSize: 18,
    shadowSpreadRadius: 2,
    shadowBlurRadius: 10,
    shadowAlpha: 0.6,
  );

  /// 小サイズの設定（プレビュー）
  static const LedDisplayConfig small = LedDisplayConfig(
    size: 40,
    spacing: 8,
    borderWidth: 2,
    fontSize: 12,
    shadowSpreadRadius: 1,
    shadowBlurRadius: 6,
    shadowAlpha: 0.5,
  );
}
