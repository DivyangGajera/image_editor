import 'package:flutter/foundation.dart';

/// Represents the geometric placement and source of an individual image cell in a collage.
@immutable
class CollageCell {
  const CollageCell({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.zIndex,
    required this.sourceImagePath,
  });

  /// Normalized horizontal center on canvas (0.0 to 1.0).
  final double x;

  /// Normalized vertical center on canvas (0.0 to 1.0).
  final double y;

  /// Width of cell in canvas pixels.
  final double width;

  /// Height of cell in canvas pixels.
  final double height;

  /// Stacking order z-index.
  final int zIndex;

  /// Local filesystem path of the source image.
  final String sourceImagePath;

  CollageCell copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    String? sourceImagePath,
  }) {
    return CollageCell(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      sourceImagePath: sourceImagePath ?? this.sourceImagePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollageCell &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          zIndex == other.zIndex &&
          sourceImagePath == other.sourceImagePath;

  @override
  int get hashCode => Object.hash(x, y, width, height, zIndex, sourceImagePath);
}
