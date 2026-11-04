import 'dart:io';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/stickers/domain/models/user_sticker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'user_sticker_repository.g.dart';

/// Persists the user's sticker library: records in Hive, images under
/// `<app_documents_dir>/stickers/`. Only app-relative paths are stored.
class UserStickerRepository {
  UserStickerRepository({
    Future<Directory> Function()? getBaseDir,
    this.stickersBox,
  }) : _getBaseDir = getBaseDir ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _getBaseDir;
  Box<UserSticker>? stickersBox;

  Future<Box<UserSticker>> _box() async {
    final open = stickersBox;
    if (open != null && open.isOpen) return open;
    final box = Hive.isBoxOpen(StorageKeys.userStickersBox)
        ? Hive.box<UserSticker>(StorageKeys.userStickersBox)
        : await Hive.openBox<UserSticker>(StorageKeys.userStickersBox);
    stickersBox = box;
    return box;
  }

  /// All user stickers, newest first.
  Future<List<UserSticker>> getAll() async {
    final stickers = (await _box()).values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return stickers;
  }

  /// Stores encoded image [bytes] ([extension] without dot) as a new sticker.
  Future<UserSticker> save({
    required Uint8List bytes,
    required String extension,
    required int width,
    required int height,
    DateTime? now,
  }) async {
    final id = const Uuid().v4();
    final relativePath = p.posix.join(StorageKeys.userStickersDirectory, '$id.$extension');
    final file = await resolve(relativePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);

    final sticker = UserSticker(
      id: id,
      relativePath: relativePath,
      width: width,
      height: height,
      addedAt: now ?? DateTime.now(),
    );
    await (await _box()).put(id, sticker);
    return sticker;
  }

  /// Removes [sticker] from the library. Projects keep their own copies.
  Future<void> delete(UserSticker sticker) async {
    await (await _box()).delete(sticker.id);
    final file = await resolve(sticker.relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Resolves an app-relative path to an absolute file at runtime.
  Future<File> resolve(String relativePath) async {
    final base = await _getBaseDir();
    return File(p.join(base.path, relativePath));
  }
}

/// App-wide singleton [UserStickerRepository].
@Riverpod(keepAlive: true)
UserStickerRepository userStickerRepository(Ref ref) => UserStickerRepository();
