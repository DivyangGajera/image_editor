/// Application-wide constants for canvas defaults, constraints, and formats.
abstract final class AppConstants {
  /// Default canvas dimensions
  static const double defaultCanvasWidth = 1080.0;
  static const double defaultCanvasHeight = 1920.0;

  /// Layer limits & thresholds
  static const int maxLayersCount = 100;
  static const int maxUndoHistoryDepth = 500;
  static const int inMemoryHistoryDepth = 50;
  static const int historyPrefetchThreshold = 5;

  /// Rendering & export defaults
  static const int defaultExportQuality = 95;
  static const String appTitle = 'Offline Image Editor';
}
