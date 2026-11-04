import 'package:flutter/foundation.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/export/application/canvas_export_service.dart';
import 'package:image_editor/features/export/domain/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'export_notifier.g.dart';

/// State representation for the canvas export workflow.
@immutable
class ExportState {
  const ExportState({
    this.isExporting = false,
    this.progress,
    this.exportedFilePath,
    this.exportedBytes,
    this.error,
  });

  /// Whether headless rendering and file writing are in progress.
  final bool isExporting;

  /// Optional fractional progress value between 0.0 and 1.0.
  final double? progress;

  /// Absolute file system path of the exported file once saved.
  final String? exportedFilePath;

  /// In-memory raw bytes of the exported image.
  final Uint8List? exportedBytes;

  /// Error message if export failed.
  final String? error;

  ExportState copyWith({
    bool? isExporting,
    double? progress,
    String? exportedFilePath,
    Uint8List? exportedBytes,
    String? error,
    bool clearError = false,
    bool clearExport = false,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      progress: progress ?? this.progress,
      exportedFilePath:
          clearExport ? null : (exportedFilePath ?? this.exportedFilePath),
      exportedBytes:
          clearExport ? null : (exportedBytes ?? this.exportedBytes),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportState &&
          runtimeType == other.runtimeType &&
          isExporting == other.isExporting &&
          progress == other.progress &&
          exportedFilePath == other.exportedFilePath &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
        isExporting,
        progress,
        exportedFilePath,
        error,
      );
}

/// Riverpod notifier coordinating headless export jobs and local gallery persistence.
@Riverpod(keepAlive: true)
class ExportNotifier extends _$ExportNotifier {
  @override
  ExportState build() => const ExportState();

  /// Executes the headless render pipeline and saves the resulting image to disk.
  Future<String?> exportProject({
    required ProjectModel project,
    required ExportConfig config,
    String? filename,
  }) async {
    state = const ExportState(isExporting: true);

    try {
      final service = ref.read(canvasExportServiceProvider);
      final bytes = await service.renderCanvasToBytes(
        project: project,
        config: config,
      );

      final extension = config.format == ExportFormat.png ? 'png' : 'jpg';
      final actualFilename =
          filename ?? 'export_${project.id}_${const Uuid().v4()}.$extension';

      final savedPath = await service.saveExportToGallery(
        bytes: bytes,
        filename: actualFilename,
      );

      state = ExportState(
        isExporting: false,
        exportedFilePath: savedPath,
        exportedBytes: bytes,
      );

      return savedPath;
    } catch (e) {
      state = ExportState(
        isExporting: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Clears previous export data.
  void clear() {
    state = const ExportState();
  }
}
