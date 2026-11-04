import 'dart:math' as math;
import 'dart:ui';

import 'package:image_editor/features/layers/domain/models/doodle_layer.dart';

/// Geometry rules for [DoodleLayer]s.
///
/// A doodle's [DoodleLayer.points] are normalized to the canvas size and are
/// relative to the top-left of the stroke's bounding box (so every coordinate
/// is >= 0). The layer's `x`/`y` is the bounding-box center. This keeps a
/// doodle's hit area and selection box tight around the stroke, and lets it be
/// moved, scaled and rotated like any other layer.
abstract final class DoodleGeometry {
  /// Extra room, in canvas units, reserved around glowing strokes.
  static const double glowExtent = 8.0;

  /// Padding around the stroke centerline so round caps and glow are not clipped.
  static double padding(DoodleLayer layer) =>
      layer.strokeWidth / 2.0 + (layer.hasGlow ? glowExtent : 0.0);

  /// Size of the doodle's local box in canvas units, including [padding].
  static Size localSize(DoodleLayer layer, Size canvasSize) {
    var maxX = 0.0;
    var maxY = 0.0;
    for (final point in layer.points) {
      maxX = math.max(maxX, point[0]);
      maxY = math.max(maxY, point[1]);
    }
    final pad = padding(layer);
    return Size(
      maxX * canvasSize.width + pad * 2.0,
      maxY * canvasSize.height + pad * 2.0,
    );
  }

  /// Builds a doodle layer from a stroke captured in canvas-normalized
  /// coordinates (0..1 across the whole canvas).
  static DoodleLayer fromCanvasPoints({
    required String id,
    required List<List<double>> canvasPoints,
    required int strokeColorValue,
    required double strokeWidth,
    required bool hasGlow,
  }) {
    if (canvasPoints.isEmpty) {
      throw ArgumentError.value(canvasPoints, 'canvasPoints', 'must not be empty');
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final point in canvasPoints) {
      minX = math.min(minX, point[0]);
      minY = math.min(minY, point[1]);
      maxX = math.max(maxX, point[0]);
      maxY = math.max(maxY, point[1]);
    }

    return DoodleLayer(
      id: id,
      x: (minX + maxX) / 2.0,
      y: (minY + maxY) / 2.0,
      points: <List<double>>[
        for (final point in canvasPoints) <double>[point[0] - minX, point[1] - minY],
      ],
      strokeColorValue: strokeColorValue,
      strokeWidth: strokeWidth,
      hasGlow: hasGlow,
    );
  }
}
