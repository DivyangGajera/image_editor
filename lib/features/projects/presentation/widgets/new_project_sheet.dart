import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/features/projects/domain/canvas_format.dart';
import 'package:image_picker/image_picker.dart';

/// How the user chose to start a new project.
sealed class NewProjectChoice {
  const NewProjectChoice();
}

/// An empty canvas of [size].
class BlankCanvasChoice extends NewProjectChoice {
  const BlankCanvasChoice(this.size);
  final Size size;
}

/// A canvas shaped like a photo picked from [source].
class PhotoChoice extends NewProjectChoice {
  const PhotoChoice(this.source);
  final ImageSource source;
}

/// The collage and filmstrip builder.
class CollageChoice extends NewProjectChoice {
  const CollageChoice();
}

/// Bottom sheet for starting a project: canvas presets, a custom size, a
/// photo, or a collage.
class NewProjectSheet extends StatelessWidget {
  const NewProjectSheet({super.key});

  static Future<NewProjectChoice?> show(BuildContext context) {
    return showModalBottomSheet<NewProjectChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const NewProjectSheet(),
    );
  }

  Future<void> _pickCustomSize(BuildContext context) async {
    final size = await showDialog<Size>(
      context: context,
      builder: (_) => const _CustomSizeDialog(),
    );
    if (size != null && context.mounted) {
      Navigator.of(context).pop(BlankCanvasChoice(size));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New project', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4.0),
            Text(
              'Pick a canvas size. You can export at higher quality later.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16.0),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              childAspectRatio: 0.72,
              children: [
                for (final format in CanvasFormat.values)
                  _FormatTile(
                    key: ValueKey('format_${format.name}'),
                    format: format,
                    onTap: () => Navigator.of(context).pop(BlankCanvasChoice(format.size)),
                  ),
              ],
            ),
            const SizedBox(height: 12.0),
            _StartOption(
              key: const ValueKey('start_custom_size'),
              icon: Icons.aspect_ratio_rounded,
              title: 'Custom size',
              subtitle:
                  'Any size from ${CanvasFormat.minCustomSide} to ${CanvasFormat.maxCustomSide} px',
              onTap: () => _pickCustomSize(context),
            ),
            _StartOption(
              key: const ValueKey('start_from_gallery'),
              icon: Icons.photo_library_outlined,
              title: 'Edit a photo',
              subtitle: 'The canvas takes the shape of your photo',
              onTap: () => Navigator.of(context).pop(const PhotoChoice(ImageSource.gallery)),
            ),
            _StartOption(
              key: const ValueKey('start_from_camera'),
              icon: Icons.photo_camera_outlined,
              title: 'Take a photo',
              subtitle: 'Start from a new camera shot',
              onTap: () => Navigator.of(context).pop(const PhotoChoice(ImageSource.camera)),
            ),
            _StartOption(
              key: const ValueKey('start_collage'),
              icon: Icons.auto_awesome_mosaic_outlined,
              title: 'Collage or filmstrip',
              subtitle: 'Combine 2 to 9 photos into one layout',
              onTap: () => Navigator.of(context).pop(const CollageChoice()),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({super.key, required this.format, required this.onTap});

  final CanvasFormat format;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: format.width / format.height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: colors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                format.label,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                format.ratioLabel,
                style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartOption extends StatelessWidget {
  const _StartOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      leading: CircleAvatar(
        backgroundColor: colors.secondaryContainer,
        foregroundColor: colors.onSecondaryContainer,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

/// Asks for a custom canvas width and height within the allowed range.
class _CustomSizeDialog extends StatefulWidget {
  const _CustomSizeDialog();

  @override
  State<_CustomSizeDialog> createState() => _CustomSizeDialogState();
}

class _CustomSizeDialogState extends State<_CustomSizeDialog> {
  final _width = TextEditingController(text: '1080');
  final _height = TextEditingController(text: '1080');

  int? get _parsedWidth => int.tryParse(_width.text);
  int? get _parsedHeight => int.tryParse(_height.text);

  bool get _isValid {
    final w = _parsedWidth;
    final h = _parsedHeight;
    return w != null && h != null && CanvasFormat.isValidCustomSize(w, h);
  }

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController controller, String key) {
    return Expanded(
      child: TextField(
        key: ValueKey(key),
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label, suffixText: 'px'),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom size'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _field('Width', _width, 'custom_width'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('x'),
              ),
              _field('Height', _height, 'custom_height'),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            'Each side must be between ${CanvasFormat.minCustomSide} and '
            '${CanvasFormat.maxCustomSide} px.',
            style: TextStyle(
              color: _isValid
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('custom_size_create'),
          onPressed: _isValid
              ? () => Navigator.of(context).pop(
                    Size(_parsedWidth!.toDouble(), _parsedHeight!.toDouble()),
                  )
              : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
