import 'dart:ui';

import 'package:image_editor/core/utils/app_logger.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/history/data/history_manager.dart';
import 'package:image_editor/features/images/application/image_import_service.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/projects/application/project_thumbnail_service.dart';
import 'package:image_editor/features/projects/domain/canvas_format.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'projects_notifier.g.dart';

/// All saved projects, most recently edited first, plus project management.
@Riverpod(keepAlive: true)
class ProjectsNotifier extends _$ProjectsNotifier {
  /// Title given to new projects until the user renames them.
  static const String defaultTitle = 'Untitled design';

  // Resolved once per build so no method touches `ref` after an await: work
  // may still be running (e.g. a thumbnail render) when the provider is
  // disposed.
  late ProjectRepository _repository;
  late ImageImportService _imageImport;
  late ProjectThumbnailService _thumbnails;

  @override
  Future<List<ProjectModel>> build() {
    _repository = ref.watch(projectRepositoryProvider);
    _imageImport = ref.watch(imageImportServiceProvider);
    _thumbnails = ref.watch(projectThumbnailServiceProvider);
    return _repository.getAllProjects();
  }

  /// Creates an empty project with a canvas of [canvasSize].
  Future<ProjectModel> createBlank({required Size canvasSize, String? title}) async {
    final now = DateTime.now();
    final project = ProjectModel(
      id: const Uuid().v4(),
      title: _cleanTitle(title) ?? defaultTitle,
      canvasWidth: canvasSize.width,
      canvasHeight: canvasSize.height,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.saveProject(project);
    await _refreshThumbnail(project);
    await _reload();
    return project;
  }

  /// Lets the user pick a photo and creates a project whose canvas matches
  /// the photo's aspect ratio, with the photo filling the canvas.
  ///
  /// Returns `null` (and leaves nothing behind) if the user cancels.
  Future<ProjectModel?> createFromPhoto(ImageSource source) async {
    final id = const Uuid().v4();
    final photo = await _imageImport.importPhoto(source: source, projectId: id);
    if (photo == null) return null;

    final canvasSize = CanvasFormat.sizeForPhoto(photo.size);
    final now = DateTime.now();
    final project = ProjectModel(
      id: id,
      title: defaultTitle,
      canvasWidth: canvasSize.width,
      canvasHeight: canvasSize.height,
      createdAt: now,
      updatedAt: now,
      layers: [
        ImageLayer(
          id: const Uuid().v4(),
          x: 0.5,
          y: 0.5,
          scale: canvasSize.width / photo.width,
          relativeImagePath: photo.relativePath,
        ),
      ],
    );
    await _repository.saveProject(project);
    await _refreshThumbnail(project);
    await _reload();
    return project;
  }

  /// Renames project [id]. Blank titles are ignored.
  Future<void> rename(String id, String title) async {
    final cleaned = _cleanTitle(title);
    final project = await _repository.loadProject(id);
    if (cleaned == null || project == null) return;

    await _repository.saveProject(
      project.copyWith(title: cleaned, updatedAt: DateTime.now()),
    );
    await _reload();
  }

  /// Duplicates project [id] including its files. Returns the copy.
  Future<ProjectModel?> duplicate(String id) async {
    final project = await _repository.loadProject(id);
    if (project == null) return null;

    final copy = await _repository.duplicateProject(
      project,
      newId: const Uuid().v4(),
      title: '${project.title} (copy)',
    );
    await _reload();
    return copy;
  }

  /// Deletes project [id], its files and its undo history.
  Future<void> delete(String id) async {
    await _repository.deleteProject(id);
    try {
      await HistoryManager.deleteFromDisk(id);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete undo history of project $id',
        tag: 'Projects',
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _reload();
  }

  /// Call after the editor closes: refreshes the project's thumbnail and the
  /// list order (most recently edited first).
  Future<void> onProjectEdited(String id) async {
    final project = await _repository.loadProject(id);
    if (project != null) {
      await _refreshThumbnail(project);
    }
    await _reload();
  }

  Future<void> _reload() async {
    final projects = await _repository.getAllProjects();
    if (ref.mounted) state = AsyncData(projects);
  }

  /// Thumbnails are a convenience: a failure must never block project changes.
  Future<void> _refreshThumbnail(ProjectModel project) async {
    try {
      await _thumbnails.refresh(project);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to render thumbnail for project ${project.id}',
        tag: 'Projects',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static String? _cleanTitle(String? title) {
    final trimmed = title?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
