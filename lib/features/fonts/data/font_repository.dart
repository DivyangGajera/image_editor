import 'dart:io';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/fonts/domain/font_entry.dart';
import 'package:image_editor/features/fonts/domain/font_file_validator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'font_repository.g.dart';

/// Persists the app-wide font library: metadata in Hive, files under
/// `<app_documents_dir>/fonts/`. Only app-relative paths are stored.
class FontRepository {
  FontRepository({
    Future<Directory> Function()? getBaseDir,
    this.fontsBox,
  }) : _getBaseDir = getBaseDir ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _getBaseDir;
  Box<FontEntry>? fontsBox;

  Future<Box<FontEntry>> _box() async {
    final open = fontsBox;
    if (open != null && open.isOpen) return open;
    final box = Hive.isBoxOpen(StorageKeys.fontsBox)
        ? Hive.box<FontEntry>(StorageKeys.fontsBox)
        : await Hive.openBox<FontEntry>(StorageKeys.fontsBox);
    fontsBox = box;
    return box;
  }

  /// All installed fonts, sorted by display name.
  Future<List<FontEntry>> getAll() async {
    final fonts = (await _box()).values.toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return fonts;
  }

  /// Saves font [bytes] of [format] as a new library entry.
  Future<FontEntry> save({
    required String family,
    required String displayName,
    required bool isImported,
    required Uint8List bytes,
    required FontFileFormat format,
    DateTime? now,
  }) async {
    final id = const Uuid().v4();
    final relativePath = p.posix.join(StorageKeys.fontsDirectory, '$id.${format.extension}');
    final file = await resolve(relativePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);

    final entry = FontEntry(
      id: id,
      family: family,
      displayName: displayName,
      isImported: isImported,
      relativePath: relativePath,
      sizeBytes: bytes.length,
      addedAt: now ?? DateTime.now(),
    );
    await (await _box()).put(id, entry);
    return entry;
  }

  /// Removes [entry] and its file.
  Future<void> delete(FontEntry entry) async {
    await (await _box()).delete(entry.id);
    final file = await resolve(entry.relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Reads the font file of [entry].
  Future<Uint8List> readBytes(FontEntry entry) async =>
      (await resolve(entry.relativePath)).readAsBytes();

  /// Resolves an app-relative path to an absolute file at runtime.
  Future<File> resolve(String relativePath) async {
    final base = await _getBaseDir();
    return File(p.join(base.path, relativePath));
  }
}

/// App-wide singleton [FontRepository].
@Riverpod(keepAlive: true)
FontRepository fontRepository(Ref ref) => FontRepository();
