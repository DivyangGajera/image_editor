import 'dart:io';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/export/domain/models/watermark_config.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'watermark_settings_repository.g.dart';

/// Remembers the brand watermark: settings in the Hive settings box, the
/// logo image under `<app_documents_dir>/branding/`.
class WatermarkSettingsRepository {
  WatermarkSettingsRepository({
    Future<Directory> Function()? getBaseDir,
    this.settingsBox,
  }) : _getBaseDir = getBaseDir ?? getApplicationDocumentsDirectory;

  static const String watermarkKey = 'brand_watermark';

  final Future<Directory> Function() _getBaseDir;
  Box<dynamic>? settingsBox;

  Future<Box<dynamic>> _box() async {
    final open = settingsBox;
    if (open != null && open.isOpen) return open;
    final box = Hive.isBoxOpen(StorageKeys.settingsBox)
        ? Hive.box<dynamic>(StorageKeys.settingsBox)
        : await Hive.openBox<dynamic>(StorageKeys.settingsBox);
    settingsBox = box;
    return box;
  }

  /// The saved watermark, or the defaults if none was saved yet.
  Future<WatermarkConfig> load() async {
    final stored = (await _box()).get(watermarkKey);
    return stored is Map ? WatermarkConfig.fromMap(stored) : const WatermarkConfig();
  }

  Future<void> save(WatermarkConfig config) async {
    await (await _box()).put(watermarkKey, config.toMap());
  }

  /// Stores logo [bytes] under a new name (so cached images never show a
  /// stale logo) and returns its app-relative path.
  Future<String> saveLogo(Uint8List bytes, String extension) async {
    final relativePath = p.posix.join(
      StorageKeys.brandingDirectory,
      'logo_${const Uuid().v4()}.$extension',
    );
    final file = await resolve(relativePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return relativePath;
  }

  Future<void> deleteFile(String relativePath) async {
    final file = await resolve(relativePath);
    if (await file.exists()) await file.delete();
  }

  Future<File> resolve(String relativePath) async {
    final base = await _getBaseDir();
    return File(p.join(base.path, relativePath));
  }
}

/// App-wide singleton [WatermarkSettingsRepository].
@Riverpod(keepAlive: true)
WatermarkSettingsRepository watermarkSettingsRepository(Ref ref) =>
    WatermarkSettingsRepository();
