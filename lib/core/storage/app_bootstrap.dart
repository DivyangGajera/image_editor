import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/hive_registrar.g.dart';

/// One-time application startup: storage engine, type adapters and global boxes.
///
/// Must complete before `runApp`, because repositories assume Hive is
/// initialized and every adapter is registered.
abstract final class AppBootstrap {
  /// Sub-directory of the app documents directory that holds Hive box files,
  /// keeping them apart from project sandboxes and the font library.
  static const String hiveSubDirectory = 'hive';

  /// Initializes Hive, registers all generated adapters and opens global boxes.
  ///
  /// [hivePath] overrides the storage directory (used by tests); by default the
  /// boxes live in `<app_documents_dir>/hive/`.
  static Future<void> initialize({String? hivePath}) async {
    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter(hiveSubDirectory);
    }

    registerAdapters();

    if (!Hive.isBoxOpen(StorageKeys.projectsBox)) {
      await Hive.openBox<ProjectModel>(StorageKeys.projectsBox);
    }
  }

  /// Registers every generated Hive adapter exactly once.
  ///
  /// Safe to call repeatedly (e.g. across tests sharing one isolate).
  static void registerAdapters() {
    if (Hive.isAdapterRegistered(HiveTypeIds.projectModel)) return;
    Hive.registerAdapters();
  }
}
