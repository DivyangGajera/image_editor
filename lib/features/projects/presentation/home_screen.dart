import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/core/widgets/busy_overlay.dart';
import 'package:image_editor/core/utils/app_logger.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/collage/presentation/screens/collage_setup_screen.dart';
import 'package:image_editor/features/editor/presentation/editor_screen.dart';
import 'package:image_editor/features/projects/application/projects_notifier.dart';
import 'package:image_editor/features/projects/presentation/widgets/empty_projects_view.dart';
import 'package:image_editor/features/projects/presentation/widgets/create_options.dart';
import 'package:image_editor/features/projects/presentation/widgets/project_actions_sheet.dart';
import 'package:image_editor/features/projects/presentation/widgets/project_card.dart';
import 'package:image_editor/features/segmentation/presentation/background_removal_prompt.dart';

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

  Future<void> _createProject(BuildContext context, WidgetRef ref, NewProjectChoice choice) async {
    final notifier = ref.read(projectsProvider.notifier);
    try {
      final ProjectModel? project;
      switch (choice) {
        case BlankCanvasChoice(:final size):
          project = await notifier.createBlank(canvasSize: size);
        case PhotoChoice(:final source):
          final pending = await BusyOverlay.during(
            context,
            message: 'Importing photo…',
            task: (showBusy) => notifier.importPhotoForNewProject(source, onPicked: showBusy),
          );
          if (pending == null || !context.mounted) return;
          final bytes = await notifier.readPendingPhoto(pending);
          if (!context.mounted) return;
          final cutout = await BackgroundRemovalPrompt.show(context, imageBytes: bytes);
          project = await notifier.createFromImportedPhoto(pending, cutoutPng: cutout);
        case CollageChoice():
          project = await Navigator.of(context).push<ProjectModel>(
            MaterialPageRoute(builder: (_) => const CollageSetupScreen()),
          );
      }
      if (project != null && context.mounted) {
        await _open(context, ref, project.id);
      }
    } catch (error, stackTrace) {
      AppLogger.error('Could not create a project', tag: 'Projects', error: error, stackTrace: stackTrace);
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final projects = ref.watch(projectsProvider);
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appShortName,
                      style: theme.textTheme.headlineMedium?.copyWith(color: colors.primary),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'What are you making today?',
                      style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24.0),
                    Text('Create', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12.0),
                    CreateGrid(onChoice: (choice) => _createProject(context, ref, choice)),
                    const SizedBox(height: 28.0),
                    Text('Recent designs', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12.0),
                  ],
                ),
              ),
            ),
            switch (projects) {
              AsyncData(:final value) when value.isEmpty => const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 24.0),
                  sliver: SliverToBoxAdapter(child: EmptyProjectsView()),
                ),
              AsyncData(:final value) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 32.0),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240.0,
                      mainAxisSpacing: 12.0,
                      crossAxisSpacing: 12.0,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      final project = value[index];
                      return ProjectCard(
                        key: ValueKey('project_card_${project.id}'),
                        project: project,
                        now: now,
                        onOpen: () => _open(context, ref, project.id),
                        onShowActions: () => _showActions(context, ref, project),
                      );
                    },
                  ),
                ),
              AsyncError() => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
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
                ),
              _ => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            },
          ],
        ),
      ),
    );
  }
}
