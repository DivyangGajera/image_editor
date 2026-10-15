import 'package:flutter/foundation.dart';
import 'package:image_editor/core/constants/app_constants.dart';

/// Available layout arrangement presets for collages and filmstrips.
enum CollageLayoutType {
  /// Images stacked horizontally side-by-side.
  horizontalStrip,

  /// Images stacked vertically in a classic photobooth / filmstrip style.
  verticalStrip,

  /// Images arranged in an MxN matrix grid.
  gridMatrix,
}

/// Configuration settings determining the layout geometry and borders of a collage.
@immutable
class CollageConfig {
  const CollageConfig({
    this.layoutType = CollageLayoutType.gridMatrix,
    this.rows = 2,
    this.cols = 2,
    this.spacing = 8.0,
    this.borderWidth = 4.0,
    this.borderColorValue = 0xFFFFFFFF, // Clean white
    this.outerMargin = 16.0,
    this.canvasWidth = AppConstants.defaultCanvasWidth,
    this.canvasHeight = AppConstants.defaultCanvasWidth, // Default square 1080x1080
  });

  /// The active layout pattern.
  final CollageLayoutType layoutType;

  /// Number of rows for grid layouts.
  final int rows;

  /// Number of columns for grid layouts.
  final int cols;

  /// Inner spacing gap between individual image cells (in canvas pixels).
  final double spacing;

  /// Stroke border width framing each cell (in canvas pixels).
  final double borderWidth;

  /// ARGB integer representation of the border color.
  final int borderColorValue;

  /// Outer padding margin from the canvas boundary (in canvas pixels).
  final double outerMargin;

  /// Target canvas pixel width.
  final double canvasWidth;

  /// Target canvas pixel height.
  final double canvasHeight;

  CollageConfig copyWith({
    CollageLayoutType? layoutType,
    int? rows,
    int? cols,
    double? spacing,
    double? borderWidth,
    int? borderColorValue,
    double? outerMargin,
    double? canvasWidth,
    double? canvasHeight,
  }) {
    return CollageConfig(
      layoutType: layoutType ?? this.layoutType,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      spacing: spacing ?? this.spacing,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColorValue: borderColorValue ?? this.borderColorValue,
      outerMargin: outerMargin ?? this.outerMargin,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollageConfig &&
          runtimeType == other.runtimeType &&
          layoutType == other.layoutType &&
          rows == other.rows &&
          cols == other.cols &&
          spacing == other.spacing &&
          borderWidth == other.borderWidth &&
          borderColorValue == other.borderColorValue &&
          outerMargin == other.outerMargin &&
          canvasWidth == other.canvasWidth &&
          canvasHeight == other.canvasHeight;

  @override
  int get hashCode => Object.hash(
        layoutType,
        rows,
        cols,
        spacing,
        borderWidth,
        borderColorValue,
        outerMargin,
        canvasWidth,
        canvasHeight,
      );
}
