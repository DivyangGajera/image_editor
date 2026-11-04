import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/collage/presentation/screens/collage_setup_screen.dart';
import 'package:image_editor/features/editor/presentation/editor_screen.dart';
import 'package:image_editor/features/projects/application/projects_notifier.dart';
import 'package:image_editor/features/projects/presentation/widgets/empty_projects_view.dart';
import 'package:image_editor/features/projects/presentation/widgets/new_project_sheet.dart';
import 'package:image_editor/features/projects/presentation/widgets/project_actions_sheet.dart';
import 'package:image_editor/features/projects/presentation/widgets/project_card.dart';

/// Opens the editor for a project; injectable so tests can observe navigation.
typedef OpenEditor = Future<void> Function(BuildContext context, String projectId);

Future<void> _pushEditor(BuildContext context, String projectId) {
  return Navigator.of(context).push(EditorScreen.route(projectId));
}

/// The project gallery: saved projects with thumbnails, or a first-run empty
/// state, plus the entry point for creating new projects.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.openEditor = _pushEditor});

  final OpenEditor openEditor;

  Future<void> _open(BuildContext context, WidgetRef ref, String projectId) async {
    await openEditor(context, projectId);
    // Back from the editor: refresh the thumbnail and "last edited" order.
    await ref.read(projectsProvider.notifier).onProjectEdited(projectId);
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createProject(BuildContext context, WidgetRef ref) async {
    final choice = await NewProjectSheet.show(context);
    if (choice == null || !context.mounted) return;

    final notifier = ref.read(projectsProvider.notifier);
    try {
      final ProjectModel? project;
      switch (choice) {
        case BlankCanvasChoice(:final size):
          project = await notifier.createBlank(canvasSize: size);
        case PhotoChoice(:final source):
          project = await notifier.createFromPhoto(source);
        case CollageChoice():
          project = await Navigator.of(context).push<ProjectModel>(
            MaterialPageRoute(builder: (_) => const CollageSetupScreen()),
          );
      }
      if (project != null && context.mounted) {
        await _open(context, ref, project.id);
      }
    } catch (_) {
      if (context.mounted) _showError(context, 'Could not create the project.');
    }
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref, ProjectModel project) async {
    final action = await ProjectActionsSheet.show(context, project);
    if (action == null || !context.mounted) return;

    final notifier = ref.read(projectsProvider.notifier);
    switch (action) {
      case ProjectAction.open:
        await _open(context, ref, project.id);
      case ProjectAction.rename:
        final title = await showRenameProjectDialog(context, project.title);
        if (title != null) await notifier.rename(project.id, title);
      case ProjectAction.duplicate:
        await notifier.duplicate(project.id);
      case ProjectAction.delete:
        if (await confirmDeleteProject(context, project.title)) {
          await notifier.delete(project.id);
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final hasProjects = projects.value?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appShortName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
      floatingActionButton: hasProjects
          ? FloatingActionButton.extended(
              key: const ValueKey('new_project_fab'),
              onPressed: () => _createProject(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New project'),
            )
          : null,
      body: switch (projects) {
        AsyncData(:final value) when value.isEmpty =>
          EmptyProjectsView(onCreate: () => _createProject(context, ref)),
        AsyncData(:final value) => _ProjectGrid(
            projects: value,
            onOpen: (project) => _open(context, ref, project.id),
            onShowActions: (project) => _showActions(context, ref, project),
          ),
        AsyncError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your projects could not be loaded.'),
                const SizedBox(height: 12.0),
                OutlinedButton(
                  onPressed: () => ref.invalidate(projectsProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ProjectGrid extends StatelessWidget {
  const _ProjectGrid({
    required this.projects,
    required this.onOpen,
    required this.onShowActions,
  });

  final List<ProjectModel> projects;
  final ValueChanged<ProjectModel> onOpen;
  final ValueChanged<ProjectModel> onShowActions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return GridView.builder(
      // Bottom padding keeps the last row clear of the floating button.
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 96.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240.0,
        mainAxisSpacing: 12.0,
        crossAxisSpacing: 12.0,
        childAspectRatio: 0.78,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ProjectCard(
          key: ValueKey('project_card_${project.id}'),
          project: project,
          now: now,
          onOpen: () => onOpen(project),
          onShowActions: () => onShowActions(project),
        );
      },
    );
  }
}
