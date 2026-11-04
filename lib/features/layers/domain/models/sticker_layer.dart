import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'canvas_layer.dart';

part 'sticker_layer.g.dart';

/// A sticker on the canvas: either a bundled asset or one of the user's own
/// stickers, copied into the project so the design stays self-contained.
@HiveType(typeId: HiveTypeIds.stickerLayer)
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
    this.relativeFilePath,
  });

  /// Flutter asset bundle path (e.g. `assets/stickers/emoji_1.png`), used
  /// when [relativeFilePath] is null. For user stickers it keeps the
  /// library path the sticker came from.
  @HiveField(7)
  final String assetPath;

  /// Project-relative path of a user sticker's image file, or null for
  /// bundled stickers.
  @HiveField(8)
  final String? relativeFilePath;

  /// Whether this sticker is one of the user's own (file-based) stickers.
  bool get isUserSticker => relativeFilePath != null;

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
    String? relativeFilePath,
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
      relativeFilePath: relativeFilePath ?? this.relativeFilePath,
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
        other.assetPath == assetPath &&
        other.relativeFilePath == relativeFilePath;
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
        relativeFilePath,
      );

  @override
  String toString() =>
      'StickerLayer(id: $id, assetPath: $assetPath, file: $relativeFilePath, x: $x, y: $y, '
      'scale: $scale, rotation: $rotation, zIndex: $zIndex, isVisible: $isVisible)';
}
