import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

/// Abstract base entity for all canvas layers.
///
/// Coordinates [x] and [y] represent the normalized position (0.0 to 1.0)
/// of the layer center relative to the project canvas dimensions.
@immutable
abstract class CanvasLayer {
  const CanvasLayer({
    required this.id,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.zIndex = 0,
    this.isVisible = true,
    this.isLocked = false,
  });

  /// Unique identifier for this layer.
  @HiveField(0)
  final String id;

  /// Normalized horizontal center position (0.0 = left edge, 1.0 = right edge).
  @HiveField(1)
  final double x;

  /// Normalized vertical center position (0.0 = top edge, 1.0 = bottom edge).
  @HiveField(2)
  final double y;

  /// Uniform scale factor (1.0 = 100% original size).
  @HiveField(3)
  final double scale;

  /// Rotation angle in radians.
  @HiveField(4)
  final double rotation;

  /// Stacking order index on the canvas (higher values render on top).
  @HiveField(5)
  final int zIndex;

  /// Whether the layer is currently rendered on the canvas.
  @HiveField(6)
  final bool isVisible;

  /// Whether the layer is locked against accidental moving, resizing and
  /// rotating on the canvas. Index 30 sits clear of every subclass's own
  /// fields (7–17); never reuse it.
  @HiveField(30, defaultValue: false)
  final bool isLocked;

  /// Returns an immutable copy of this layer with the given base fields replaced.
  ///
  /// Every subclass overrides this with its own type-specific fields added, so
  /// callers can update transform/stacking fields without knowing the concrete type.
  CanvasLayer copyWith({
    String? id,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
    bool? isVisible,
    bool? isLocked,
  });
}
