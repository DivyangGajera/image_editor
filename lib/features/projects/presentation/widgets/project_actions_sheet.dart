import 'package:flutter/material.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';

/// What the user chose to do with a project from its options sheet.
enum ProjectAction { open, rename, duplicate, delete }

/// Bottom sheet listing the actions for [project].
class ProjectActionsSheet extends StatelessWidget {
  const ProjectActionsSheet({super.key, required this.project});

  final ProjectModel project;

  static Future<ProjectAction?> show(BuildContext context, ProjectModel project) {
    return showModalBottomSheet<ProjectAction>(
      context: context,
      builder: (_) => ProjectActionsSheet(project: project),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    ListTile tile(ProjectAction action, IconData icon, String label, {Color? color}) {
      return ListTile(
        key: ValueKey('project_action_${action.name}'),
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color)),
        onTap: () => Navigator.of(context).pop(action),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 8.0),
            child: Text(
              project.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          tile(ProjectAction.open, Icons.edit_outlined, 'Open'),
          tile(ProjectAction.rename, Icons.drive_file_rename_outline_rounded, 'Rename'),
          tile(ProjectAction.duplicate, Icons.copy_all_outlined, 'Duplicate'),
          tile(ProjectAction.delete, Icons.delete_outline_rounded, 'Delete', color: colors.error),
        ],
      ),
    );
  }
}

/// Asks for a new project title. Returns null if cancelled.
Future<String?> showRenameProjectDialog(BuildContext context, String currentTitle) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RenameDialog(currentTitle: currentTitle),
  );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.currentTitle});

  final String currentTitle;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentTitle)
        ..selection = TextSelection(baseOffset: 0, extentOffset: widget.currentTitle.length);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename project'),
      content: TextField(
        key: const ValueKey('rename_field'),
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          key: const ValueKey('rename_save'),
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Confirms deleting [title]. Returns true only if the user confirmed.
Future<bool> confirmDeleteProject(BuildContext context, String title) async {
  final colors = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete project?'),
      content: Text('"$title" and its undo history will be permanently deleted.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm_delete'),
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
