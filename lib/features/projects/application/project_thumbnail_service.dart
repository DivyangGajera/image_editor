import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/export/application/canvas_export_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_thumbnail_service.g.dart';

/// Renders the small preview image shown on a project's gallery card.
class ProjectThumbnailService {
  ProjectThumbnailService({
    required this.exportService,
    required this.repository,
  });

  /// Longest edge of a thumbnail, in pixels.
  static const int longEdge = 480;

  final CanvasExportService exportService;
  final ProjectRepository repository;

  /// Pixel size of the thumbnail for a canvas of [canvasSize].
  static Size thumbnailSize(Size canvasSize) {
    if (canvasSize.isEmpty) return const Size(1, 1);
    final factor = longEdge / math.max(canvasSize.width, canvasSize.height);
    return Size(
      math.max(1, (canvasSize.width * factor).round()).toDouble(),
      math.max(1, (canvasSize.height * factor).round()).toDouble(),
    );
  }

  /// Re-renders and saves the thumbnail of [project], evicting the stale image
  /// from Flutter's image cache. Returns its project-relative path.
  Future<String> refresh(ProjectModel project) async {
    final bytes = await exportService.renderAtSize(
      project: project,
      outputSize: thumbnailSize(Size(project.canvasWidth, project.canvasHeight)),
    );
    final relativePath = await repository.saveThumbnail(project.id, bytes);
    final file = await repository.resolveRelativePath(relativePath);
    await FileImage(file).evict();
    return relativePath;
  }
}

/// App-wide singleton [ProjectThumbnailService].
@Riverpod(keepAlive: true)
ProjectThumbnailService projectThumbnailService(Ref ref) {
  return ProjectThumbnailService(
    exportService: ref.watch(canvasExportServiceProvider),
    repository: ref.watch(projectRepositoryProvider),
  );
}
