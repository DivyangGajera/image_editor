import 'package:hive_ce/hive.dart';
import 'canvas_layer.dart';

part 'sticker_layer.g.dart';

/// Represents a vector or pre-bundled raster sticker layer positioned on the canvas.
@HiveType(typeId: 3)
class StickerLayer extends CanvasLayer {
  const StickerLayer({
    required super.id,
    required super.x,
    required super.y,
    super.scale = 1.0,
    super.rotation = 0.0,
    super.zIndex = 0,
    super.isVisible = true,
    required this.assetPath,
  });

  /// Flutter asset bundle path (e.g. `assets/stickers/emoji_1.png`).
  @HiveField(7)
  final String assetPath;

  @override
  StickerLayer copyWith({
    String? id,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
    bool? isVisible,
    String? assetPath,
  }) {
    return StickerLayer(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      isVisible: isVisible ?? this.isVisible,
      assetPath: assetPath ?? this.assetPath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StickerLayer &&
        other.id == id &&
        other.x == x &&
        other.y == y &&
        other.scale == scale &&
        other.rotation == rotation &&
        other.zIndex == zIndex &&
        other.isVisible == isVisible &&
        other.assetPath == assetPath;
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
        assetPath,
      );

  @override
  String toString() =>
      'StickerLayer(id: $id, assetPath: $assetPath, x: $x, y: $y, '
      'scale: $scale, rotation: $rotation, zIndex: $zIndex, isVisible: $isVisible)';
}
