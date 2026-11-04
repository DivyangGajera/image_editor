import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'canvas_layer.dart';

part 'doodle_layer.g.dart';

/// Represents a freehand drawing/stroke vector layer positioned on the canvas.
@HiveType(typeId: HiveTypeIds.doodleLayer)
class DoodleLayer extends CanvasLayer {
  const DoodleLayer({
    required super.id,
    required super.x,
    required super.y,
    super.scale = 1.0,
    super.rotation = 0.0,
    super.zIndex = 0,
    super.isVisible = true,
    required this.points,
    this.strokeColorValue = 0xFFFF0000,
    this.strokeWidth = 5.0,
    this.hasGlow = false,
  });

  /// Vector coordinate path points, typically represented as normalized `[x, y]` coordinates.
  @HiveField(7)
  final List<List<double>> points;

  /// 32-bit ARGB color value of the doodle stroke.
  @HiveField(8)
  final int strokeColorValue;

  /// Width of the drawn stroke in canvas units.
  @HiveField(9)
  final double strokeWidth;

  /// Whether a neon/diffused glow effect is rendered around the stroke.
  @HiveField(10)
  final bool hasGlow;

  @override
  DoodleLayer copyWith({
    String? id,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
    bool? isVisible,
    List<List<double>>? points,
    int? strokeColorValue,
    double? strokeWidth,
    bool? hasGlow,
  }) {
    return DoodleLayer(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      isVisible: isVisible ?? this.isVisible,
      points: points ??
          this.points.map((innerList) => List<double>.from(innerList)).toList(),
      strokeColorValue: strokeColorValue ?? this.strokeColorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      hasGlow: hasGlow ?? this.hasGlow,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoodleLayer &&
        other.id == id &&
        other.x == x &&
        other.y == y &&
        other.scale == scale &&
        other.rotation == rotation &&
        other.zIndex == zIndex &&
        other.isVisible == isVisible &&
        other.strokeColorValue == strokeColorValue &&
        other.strokeWidth == strokeWidth &&
        other.hasGlow == hasGlow &&
        _arePointsEqual(other.points, points);
  }

  static bool _arePointsEqual(List<List<double>> a, List<List<double>> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!listEquals(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        x,
        y,
        scale,
        rotation,
        zIndex,
        isVisible,
        strokeColorValue,
        strokeWidth,
        hasGlow,
        points.length,
      );

  @override
  String toString() =>
      'DoodleLayer(id: $id, pointsCount: ${points.length}, strokeColorValue: $strokeColorValue, '
      'strokeWidth: $strokeWidth, hasGlow: $hasGlow, x: $x, y: $y, scale: $scale, '
      'rotation: $rotation, zIndex: $zIndex, isVisible: $isVisible)';
}
