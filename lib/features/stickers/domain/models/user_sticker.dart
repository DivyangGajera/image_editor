import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';

part 'user_sticker.g.dart';

/// A sticker the user imported into their app-wide "My stickers" library.
@immutable
@HiveType(typeId: HiveTypeIds.userSticker)
class UserSticker {
  const UserSticker({
    required this.id,
    required this.relativePath,
    required this.width,
    required this.height,
    required this.addedAt,
  });

  @HiveField(0)
  final String id;

  /// App-relative path of the image, e.g. `stickers/<id>.png`.
  @HiveField(1)
  final String relativePath;

  /// Pixel size of the stored image.
  @HiveField(2)
  final int width;

  @HiveField(3)
  final int height;

  @HiveField(4)
  final DateTime addedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSticker &&
          other.id == id &&
          other.relativePath == relativePath &&
          other.width == width &&
          other.height == height &&
          other.addedAt == addedAt;

  @override
  int get hashCode => Object.hash(id, relativePath, width, height, addedAt);
}
