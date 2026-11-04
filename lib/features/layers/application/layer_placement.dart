import 'dart:math' as math;
import 'dart:ui';

/// Initial placement rules for newly added layers.
abstract final class LayerPlacement {
  /// Fraction of the canvas a newly imported photo should occupy.
  static const double photoFraction = 0.7;

  /// Fraction of the canvas width a newly added sticker should occupy.
  static const double stickerWidthFraction = 0.35;

  /// Scale that fits content of [contentSize] (in canvas units) into
  /// [fraction] of [canvasSize] while preserving its aspect ratio.
  ///
  /// Never enlarges content beyond its natural size (scale <= 1), so small
  /// images stay crisp.
  static double fitScale({
    required Size contentSize,
    required Size canvasSize,
    double fraction = photoFraction,
  }) {
    if (contentSize.isEmpty || canvasSize.isEmpty) return 1.0;
    final scale = math.min(
      canvasSize.width * fraction / contentSize.width,
      canvasSize.height * fraction / contentSize.height,
    );
    return math.min(scale, 1.0);
  }

  /// Scale that makes content of [contentWidth] span [fraction] of the canvas
  /// width. Unlike [fitScale] this may enlarge, since stickers are designed to
  /// be resized.
  static double widthScale({
    required double contentWidth,
    required double canvasWidth,
    double fraction = stickerWidthFraction,
  }) {
    if (contentWidth <= 0 || canvasWidth <= 0) return 1.0;
    return canvasWidth * fraction / contentWidth;
  }
}
