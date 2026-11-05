import 'package:flutter/foundation.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/export/application/canvas_export_service.dart';
import 'package:image_editor/features/export/application/gallery_saver.dart';
import 'package:image_editor/features/export/domain/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'export_notifier.g.dart';

/// State of the export workflow.
@immutable
class ExportState {
  const ExportState({
    this.isExporting = false,
    this.exportedBytes,
    this.error,
  });

  /// Whether rendering and saving are in progress.
  final bool isExporting;

  /// The last successfully exported image.
  final Uint8List? exportedBytes;

  /// User-facing message of the last failure.
  final String? error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportState &&
          other.isExporting == isExporting &&
          identical(other.exportedBytes, exportedBytes) &&
          other.error == error;

  @override
  int get hashCode => Object.hash(isExporting, exportedBytes, error);
}

/// Renders a project and saves it to the gallery's app album.
@Riverpod(keepAlive: true)
class ExportNotifier extends _$ExportNotifier {
  @override
  ExportState build() => const ExportState();

  /// File name (without extension) for an export made at [time], e.g.
  /// `Chitred_20261105_093012`.
  static String fileNameFor(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${GalGallerySaver.album}_${time.year}${two(time.month)}${two(time.day)}_'
        '${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }

  /// Exports [project] with [config] and saves it to the gallery.
  ///
  /// Returns true on success; on failure the message is in [ExportState.error].
  Future<bool> exportProject({
    required ProjectModel project,
    required ExportConfig config,
  }) async {
    if (state.isExporting) return false;
    final service = ref.read(canvasExportServiceProvider);
    final gallery = ref.read(gallerySaverProvider);
    state = const ExportState(isExporting: true);

    try {
      final bytes = await service.renderCanvasToBytes(project: project, config: config);
      await gallery.save(bytes, name: fileNameFor(DateTime.now()));
      if (ref.mounted) state = ExportState(exportedBytes: bytes);
      return true;
    } on GallerySaveException catch (error) {
      if (ref.mounted) state = ExportState(error: error.message);
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = const ExportState(error: 'The image could not be created. Please try again.');
      }
      return false;
    }
  }

  /// Clears the result of the last export.
  void clear() {
    state = const ExportState();
  }
}
