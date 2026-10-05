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
