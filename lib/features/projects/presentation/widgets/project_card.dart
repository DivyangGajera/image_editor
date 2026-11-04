import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/projects/presentation/edited_label.dart';

/// Gallery card showing a project's thumbnail, title and last-edited time.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.now,
    required this.onOpen,
    required this.onShowActions,
  });

  final ProjectModel project;

  /// Reference time for the "Edited …" label.
  final DateTime now;

  final VoidCallback onOpen;
  final VoidCallback onShowActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        onLongPress: onShowActions,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: AppTheme.canvasBackdrop,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: project.canvasWidth / project.canvasHeight,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 8.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _ProjectThumbnail(projectId: project.id),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 0.0, 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          editedLabel(project.updatedAt, now),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: ValueKey('project_menu_${project.id}'),
                    tooltip: 'Project options',
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: onShowActions,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The saved thumbnail of a project, or a neutral placeholder if none exists.
class _ProjectThumbnail extends ConsumerWidget {
  const _ProjectThumbnail({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(projectRepositoryProvider);

    return FutureBuilder<File>(
      future: repository.resolveRelativePath(
        ProjectRepository.thumbnailRelativePath(projectId),
      ),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null || !file.existsSync()) {
          return const _ThumbnailPlaceholder();
        }
        return Image.file(
          file,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const _ThumbnailPlaceholder(),
        );
      },
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
