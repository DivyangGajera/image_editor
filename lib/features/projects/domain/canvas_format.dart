import 'dart:math' as math;
import 'dart:ui';

/// Canvas size presets offered when creating a project.
enum CanvasFormat {
  /// Square social post.
  square('Post', '1:1', 1080, 1080),

  /// Portrait feed post.
  portrait('Feed', '4:5', 1080, 1350),

  /// Full-screen story or reel.
  story('Story', '9:16', 1080, 1920),

  /// Landscape banner or cover.
  landscape('Banner', '16:9', 1920, 1080);

  const CanvasFormat(this.label, this.ratioLabel, this.width, this.height);

  /// Short user-facing name.
  final String label;

  /// Aspect ratio as shown to the user, e.g. `4:5`.
  final String ratioLabel;

  final int width;
  final int height;

  Size get size => Size(width.toDouble(), height.toDouble());

  /// Smallest and largest custom canvas side, in pixels.
  static const int minCustomSide = 200;
  static const int maxCustomSide = 4096;

  /// Whether [width] x [height] is an allowed custom canvas size.
  static bool isValidCustomSize(int width, int height) {
    bool inRange(int side) => side >= minCustomSide && side <= maxCustomSide;
    return inRange(width) && inRange(height);
  }

  /// Canvas size for a project started from a photo of [photoSize]: the
  /// photo's aspect ratio with a 1080 px short edge, so it matches the presets'
  /// sharpness. The long edge is capped at [maxCustomSide].
  static Size sizeForPhoto(Size photoSize) {
    if (photoSize.isEmpty) return CanvasFormat.square.size;
    final factor = math.min(
      1080 / photoSize.shortestSide,
      maxCustomSide / photoSize.longestSide,
    );
    return Size(
      (photoSize.width * factor).roundToDouble(),
      (photoSize.height * factor).roundToDouble(),
    );
  }
}
