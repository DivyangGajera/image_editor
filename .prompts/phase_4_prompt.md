Build the local storage abstraction to manage project files and sandbox isolation.
1. Create ProjectRepository in lib/features/canvas/data/project_repository.dart:
    - Future<Directory> getProjectDirectory(String projectId): resolves <app_documents_dir>/projects/<projectId>/. Ensures the folder exists.
    - Future<String> saveLayerImage(String projectId, Uint8List bytes, String filename): saves binary data inside <project_dir>/images/ and returns ONLY the relative path (e.g., projects/<projectId>/images/<filename>).
    - Future<void> saveProject(ProjectModel project): stores project metadata in Hive box projects_box.
    - Future<ProjectModel?> loadProject(String projectId): reads project from Hive.
    - Future<void> deleteProject(String projectId): removes the Hive record AND deletes the project folder from disk.

2. Create Riverpod providers for ProjectRepository.

3. Write unit tests with mock paths verifying that relative paths are always stored and absolute paths correctly resolve.