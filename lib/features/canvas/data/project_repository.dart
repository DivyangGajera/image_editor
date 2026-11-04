import 'dart:io';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_repository.g.dart';

/// App-wide singleton [ProjectRepository].
@Riverpod(keepAlive: true)
ProjectRepository projectRepository(Ref ref) => ProjectRepository();

/// Repository managing local project sandbox files, directory isolation,
/// and metadata persistence in Hive CE.
class ProjectRepository {
  ProjectRepository({
    Future<Directory> Function()? getBaseDir,
    this.projectsBox,
  }) : _getBaseDir = getBaseDir ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _getBaseDir;
  Box<ProjectModel>? projectsBox;

  /// Retrieves or opens the strongly-typed Hive box for projects metadata.
  Future<Box<ProjectModel>> _getBox() async {
    if (projectsBox != null && projectsBox!.isOpen) {
      return projectsBox!;
    }
    if (Hive.isBoxOpen(StorageKeys.projectsBox)) {
      projectsBox = Hive.box<ProjectModel>(StorageKeys.projectsBox);
    } else {
      projectsBox = await Hive.openBox<ProjectModel>(StorageKeys.projectsBox);
    }
    return projectsBox!;
  }

  /// Resolves `<app_documents_dir>/projects/<projectId>/` and guarantees the folder exists.
  Future<Directory> getProjectDirectory(String projectId) async {
    final baseDir = await _getBaseDir();
    final projectPath = p.join(baseDir.path, StorageKeys.projectsDirectory, projectId);
    final directory = Directory(projectPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// Saves image binary data inside `<project_dir>/images/<filename>` and returns
  /// ONLY the normalized project-relative path (e.g. `projects/<projectId>/images/<filename>`).
  ///
  /// Never returns or persists absolute device paths to ensure compliance with
  /// Android Play Store scoped storage rules.
  Future<String> saveLayerImage(
    String projectId,
    Uint8List bytes,
    String filename,
  ) async {
    final projectDir = await getProjectDirectory(projectId);
    final imagesDir = Directory(p.join(projectDir.path, StorageKeys.imagesDirectory));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final targetFile = File(p.join(imagesDir.path, filename));
    await targetFile.writeAsBytes(bytes, flush: true);

    // Normalize with POSIX forward slashes for cross-platform stability
    return p.posix.join(
      StorageKeys.projectsDirectory,
      projectId,
      StorageKeys.imagesDirectory,
      filename,
    );
  }

  /// Stores project metadata in the Hive CE `projects_box`.
  Future<void> saveProject(ProjectModel project) async {
    final box = await _getBox();
    await box.put(project.id, project);
  }

  /// Reads project metadata from the Hive CE `projects_box`.
  Future<ProjectModel?> loadProject(String projectId) async {
    final box = await _getBox();
    return box.get(projectId);
  }

  /// Deletes the project metadata from Hive AND completely purges
  /// the project directory sandbox from local disk.
  Future<void> deleteProject(String projectId) async {
    final box = await _getBox();
    await box.delete(projectId);

    final projectDir = await getProjectDirectory(projectId);
    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
    }
  }

  /// Retrieves all projects ordered by newest updated first.
  Future<List<ProjectModel>> getAllProjects() async {
    final box = await _getBox();
    final list = box.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// Dynamically resolves a project-relative path (e.g. `projects/<id>/images/foo.png`)
  /// to an absolute filesystem [File] at runtime.
  Future<File> resolveRelativePath(String relativePath) async {
    final baseDir = await _getBaseDir();
    return File(p.join(baseDir.path, relativePath));
  }
}
