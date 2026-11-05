import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'canvas_layer.dart';

part 'image_layer.g.dart';

/// Represents a raster image layer positioned on the canvas.
///
/// Persistent file references are strictly stored as project-relative paths
/// (e.g. `projects/<id>/images/image_1.png`) per Android Play Store Scoped Storage
/// and local storage guidelines.
@HiveType(typeId: HiveTypeIds.imageLayer)
class ImageLayer extends CanvasLayer {
  const ImageLayer({
    required super.id,
    required super.x,
    required super.y,
    super.scale = 1.0,
    super.rotation = 0.0,
    super.zIndex = 0,
    super.isVisible = true,
    super.isLocked = false,
    required this.relativeImagePath,
    this.isFlippedHorizontally = false,
    this.activeFilter,
    this.originalImagePath,
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

  // HiveField 10 held the never-used `cropRect` and is retired: never reuse it.

  /// Project-relative path to the uncropped original this image was cut
  /// from, so a crop can always be redone or reset. Null for images that
  /// were never cropped (e.g. background cutouts, collage cells).
  @HiveField(11)
  final String? originalImagePath;

  /// Whether this image is a crop of a larger original.
  bool get isCropped =>
      originalImagePath != null && originalImagePath != relativeImagePath;

  @override
  ImageLayer copyWith({
    String? id,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
    bool? isVisible,
    bool? isLocked,
    String? relativeImagePath,
    bool? isFlippedHorizontally,
    String? activeFilter,
    bool clearActiveFilter = false,
    String? originalImagePath,
  }) {
    return ImageLayer(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      relativeImagePath: relativeImagePath ?? this.relativeImagePath,
      isFlippedHorizontally:
          isFlippedHorizontally ?? this.isFlippedHorizontally,
      activeFilter:
          clearActiveFilter ? null : (activeFilter ?? this.activeFilter),
      originalImagePath: originalImagePath ?? this.originalImagePath,
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
        other.isLocked == isLocked &&
        other.relativeImagePath == relativeImagePath &&
        other.isFlippedHorizontally == isFlippedHorizontally &&
        other.activeFilter == activeFilter &&
        other.originalImagePath == originalImagePath;
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
        isLocked,
        relativeImagePath,
        isFlippedHorizontally,
        activeFilter,
        originalImagePath,
      );

  @override
  String toString() =>
      'ImageLayer(id: $id, x: $x, y: $y, scale: $scale, rotation: $rotation, '
      'zIndex: $zIndex, isVisible: $isVisible, isLocked: $isLocked, relativeImagePath: $relativeImagePath, '
      'isFlippedHorizontally: $isFlippedHorizontally, activeFilter: $activeFilter, originalImagePath: $originalImagePath)';
}
