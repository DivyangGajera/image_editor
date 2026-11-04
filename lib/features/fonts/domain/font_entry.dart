import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';

part 'font_entry.g.dart';

/// A font installed in the app-wide font library: downloaded from the Google
/// Fonts catalog or imported by the user from a .ttf/.otf file.
@immutable
@HiveType(typeId: HiveTypeIds.fontEntry)
class FontEntry {
  const FontEntry({
    required this.id,
    required this.family,
    required this.displayName,
    required this.isImported,
    required this.relativePath,
    required this.sizeBytes,
    required this.addedAt,
  });

  /// Unique ID; also the font file's base name.
  @HiveField(0)
  final String id;

  /// Family name the font is registered under and that text layers store.
  /// Re-downloading a deleted catalog font reuses the same family, so text
  /// that used it recovers automatically.
  @HiveField(1)
  final String family;

  /// Name shown to the user.
  @HiveField(2)
  final String displayName;

  /// True for fonts imported from a file, false for catalog downloads.
  @HiveField(3)
  final bool isImported;

  /// App-relative path of the font file, e.g. `fonts/<id>.ttf`.
  @HiveField(4)
  final String relativePath;

  @HiveField(5)
  final int sizeBytes;

  @HiveField(6)
  final DateTime addedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontEntry &&
          other.id == id &&
          other.family == family &&
          other.displayName == displayName &&
          other.isImported == isImported &&
          other.relativePath == relativePath &&
          other.sizeBytes == sizeBytes &&
          other.addedAt == addedAt;

  @override
  int get hashCode =>
      Object.hash(id, family, displayName, isImported, relativePath, sizeBytes, addedAt);
}
