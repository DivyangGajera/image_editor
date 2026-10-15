import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'canvas_layer.dart';

part 'image_layer.g.dart';

/// Represents a raster image layer positioned on the canvas.
///
/// Persistent file references are strictly stored as project-relative paths
/// (e.g. `projects/<id>/images/image_1.png`) per Android Play Store Scoped Storage
/// and local storage guidelines.
@HiveType(typeId: 0)
class ImageLayer extends CanvasLayer {
  const ImageLayer({
    required super.id,
    required super.x,
    required super.y,
    super.scale = 1.0,
    super.rotation = 0.0,
    super.zIndex = 0,
    super.isVisible = true,
    required this.relativeImagePath,
    this.isFlippedHorizontally = false,
    this.activeFilter,
    this.cropRect,
  });

  /// Project-relative path to the stored image file.
  @HiveField(7)
  final String relativeImagePath;

  /// Whether the image is mirrored horizontally across its vertical axis.
  @HiveField(8)
  final bool isFlippedHorizontally;

  /// Identifier of the active color filter/lut applied to this image, if any.
  @HiveField(9)
  final String? activeFilter;

  /// Normalized or pixel crop boundaries `[left, top, right, bottom]`, if cropped.
  @HiveField(10)
  final List<double>? cropRect;

  @override
  ImageLayer copyWith({
    String? id,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
    bool? isVisible,
    String? relativeImagePath,
    bool? isFlippedHorizontally,
    String? activeFilter,
    bool clearActiveFilter = false,
    List<double>? cropRect,
  }) {
    return ImageLayer(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      isVisible: isVisible ?? this.isVisible,
      relativeImagePath: relativeImagePath ?? this.relativeImagePath,
      isFlippedHorizontally:
          isFlippedHorizontally ?? this.isFlippedHorizontally,
      activeFilter:
          clearActiveFilter ? null : (activeFilter ?? this.activeFilter),
      cropRect: cropRect ?? (this.cropRect != null ? List<double>.from(this.cropRect!) : null),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageLayer &&
        other.id == id &&
        other.x == x &&
        other.y == y &&
        other.scale == scale &&
        other.rotation == rotation &&
        other.zIndex == zIndex &&
        other.isVisible == isVisible &&
        other.relativeImagePath == relativeImagePath &&
        other.isFlippedHorizontally == isFlippedHorizontally &&
        other.activeFilter == activeFilter &&
        listEquals(other.cropRect, cropRect);
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
        relativeImagePath,
        isFlippedHorizontally,
        activeFilter,
        cropRect == null ? null : Object.hashAll(cropRect!),
      );

  @override
  String toString() =>
      'ImageLayer(id: $id, x: $x, y: $y, scale: $scale, rotation: $rotation, '
      'zIndex: $zIndex, isVisible: $isVisible, relativeImagePath: $relativeImagePath, '
      'isFlippedHorizontally: $isFlippedHorizontally, activeFilter: $activeFilter, cropRect: $cropRect)';
}
