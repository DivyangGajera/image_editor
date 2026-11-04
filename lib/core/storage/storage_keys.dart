/// Constants for Hive CE box names and relative storage paths.
abstract final class StorageKeys {
  /// Box storing all ProjectModel instances
  static const String projectsBox = 'projects_box';

  /// Prefix for project-specific history undo/redo boxes: e.g. `history_<projectId>`
  static const String historyBoxPrefix = 'history_';

  /// Root directory name for relative project storage inside documents directory
  static const String projectsDirectory = 'projects';

  /// Subdirectory inside project folder for storing imported layer images
  static const String imagesDirectory = 'images';

  /// Subdirectory inside project folder for project-specific assets
  static const String assetsDirectory = 'assets';
}

/// Registry of every Hive `typeId` used by the app.
///
/// Type IDs are persisted inside box files, so an ID must NEVER be reused or
/// changed once released. Always take the next unused number for new types.
abstract final class HiveTypeIds {
  static const int imageLayer = 0;
  static const int textLayer = 1;
  static const int doodleLayer = 2;
  static const int stickerLayer = 3;
  static const int projectModel = 4;
}
