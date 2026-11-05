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

/// The home screen's "Create" grid: every way to start a design, one tap
/// each. Canvas formats come first, then photo, camera, collage and a
/// custom size.
class CreateGrid extends StatelessWidget {
  const CreateGrid({super.key, required this.onChoice});

  final ValueChanged<NewProjectChoice> onChoice;

  Future<void> _pickCustomSize(BuildContext context) async {
    final size = await showCustomSizeDialog(context);
    if (size != null) onChoice(BlankCanvasChoice(size));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10.0,
      crossAxisSpacing: 10.0,
      childAspectRatio: 0.82,
      children: [
        for (final format in CanvasFormat.values)
          CreateTile(
            key: ValueKey('format_${format.name}'),
            highlighted: format == CanvasFormat.square,
            icon: _FormatGlyph(format: format, highlighted: format == CanvasFormat.square),
            label: format.label,
            caption: format.ratioLabel,
            onTap: () => onChoice(BlankCanvasChoice(format.size)),
          ),
        CreateTile(
          key: const ValueKey('start_from_gallery'),
          icon: Icon(Icons.photo_library_outlined, color: colors.secondary),
          label: 'Photo',
          caption: 'Edit one',
          onTap: () => onChoice(const PhotoChoice(ImageSource.gallery)),
        ),
        CreateTile(
          key: const ValueKey('start_from_camera'),
          icon: Icon(Icons.photo_camera_outlined, color: colors.secondary),
          label: 'Camera',
          caption: 'Take one',
          onTap: () => onChoice(const PhotoChoice(ImageSource.camera)),
        ),
        CreateTile(
          key: const ValueKey('start_collage'),
          icon: Icon(Icons.auto_awesome_mosaic_outlined, color: colors.secondary),
          label: 'Collage',
          caption: '2–9 photos',
          onTap: () => onChoice(const CollageChoice()),
        ),
        CreateTile(
          key: const ValueKey('start_custom_size'),
          dashed: true,
          icon: Icon(Icons.aspect_ratio_rounded, color: colors.onSurfaceVariant),
          label: 'Custom',
          caption: 'Any size',
          onTap: () => _pickCustomSize(context),
        ),
      ],
    );
  }
}

/// One option of the [CreateGrid].
class CreateTile extends StatelessWidget {
  const CreateTile({
    super.key,
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.highlighted = false,
    this.dashed = false,
  });

  final Widget icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  /// The most common choice, filled with the brand color.
  final bool highlighted;

  /// A secondary choice, drawn with a lighter, transparent look.
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = highlighted ? colors.onPrimary : colors.onSurface;
    return Material(
      color: highlighted
          ? colors.primary
          : dashed
              ? Colors.transparent
              : colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: highlighted ? BorderSide.none : BorderSide(color: dashed ? colors.outline : colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 34.0, child: Center(child: icon)),
              const SizedBox(height: 8.0),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: highlighted ? colors.onPrimary.withValues(alpha: 0.85) : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An outlined rectangle with the format's aspect ratio.
class _FormatGlyph extends StatelessWidget {
  const _FormatGlyph({required this.format, required this.highlighted});

  final CanvasFormat format;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const box = 30.0;
    final ratio = format.width / format.height;
    final width = ratio >= 1 ? box : box * ratio;
    final height = ratio >= 1 ? box / ratio : box;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: highlighted ? colors.onPrimary : colors.primary, width: 2.0),
      ),
    );
  }
}

/// Asks for a custom canvas size; returns null if cancelled.
Future<Size?> showCustomSizeDialog(BuildContext context) {
  return showDialog<Size>(context: context, builder: (_) => const _CustomSizeDialog());
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
