import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/fonts/application/font_library_notifier.dart';
import 'package:image_editor/features/fonts/domain/font_catalog.dart';
import 'package:image_editor/features/fonts/presentation/font_picker_sheet.dart';
import 'package:image_editor/features/layers/domain/models/text_layer.dart';
import 'package:image_editor/features/layers/presentation/widgets/text_layer_widget.dart';
import 'package:uuid/uuid.dart';

/// Bottom sheet for adding or editing a [TextLayer]: content, font, size,
/// style, color, shadow and background box, with a live preview.
///
/// Returns the resulting layer from [show], or null if cancelled.
class TextEditSheet extends ConsumerStatefulWidget {
  const TextEditSheet({
    super.key,
    this.initialLayer,
    this.onSaved,
  });

  /// Existing layer to edit, or null when adding a new text layer.
  final TextLayer? initialLayer;

  /// Optional callback invoked when the user taps "Done".
  final ValueChanged<TextLayer>? onSaved;

  static Future<TextLayer?> show(
    BuildContext context, {
    TextLayer? initialLayer,
  }) {
    return showModalBottomSheet<TextLayer>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => TextEditSheet(initialLayer: initialLayer),
    );
  }

  @override
  ConsumerState<TextEditSheet> createState() => _TextEditSheetState();
}

class _TextEditSheetState extends ConsumerState<TextEditSheet> {
  /// Default color for new text: black, readable on the white canvas.
  static const int defaultTextColor = 0xFF000000;

  static const double minFontSize = 10.0;
  static const double maxFontSize = 120.0;

  static const List<int> paletteColors = <int>[
    0xFF000000, // Black
    0xFFFFFFFF, // White
    0xFFEF4444, // Red
    0xFFF97316, // Orange
    0xFFFACC15, // Yellow
    0xFF22C55E, // Green
    0xFF06B6D4, // Cyan
    0xFF3B82F6, // Blue
    0xFF4F46E5, // Indigo
    0xFF8B5CF6, // Violet
    0xFFEC4899, // Pink
    0xFF78350F, // Brown
  ];

  static const List<int> boxColors = <int>[
    0xCC000000, // Translucent black
    0xCCFFFFFF, // Translucent white
    0xFF111827, // Ink
    0xFFEF4444, // Red
    0xFFFACC15, // Yellow
    0xFF22C55E, // Green
    0xFF3B82F6, // Blue
    0xFFEC4899, // Pink
  ];

  late final TextEditingController _textController;
  late String _fontFamily;
  late double _fontSize;
  late bool _isBold;
  late bool _isItalic;
  late int _textColorValue;
  late bool _hasShadow;
  late int _shadowColorValue;
  late bool _hasBackgroundBox;
  late int _boxColorValue;
  late double _boxBorderRadius;

  bool get _isNew => widget.initialLayer == null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLayer;
    _textController = TextEditingController(text: initial?.text ?? 'Your text');
    _fontFamily = initial?.fontFamily ?? systemDefaultFontFamily;
    _fontSize = (initial?.fontSize ?? 28.0).clamp(minFontSize, maxFontSize);
    _isBold = initial?.isBold ?? false;
    _isItalic = initial?.isItalic ?? false;
    _textColorValue = initial?.textColorValue ?? defaultTextColor;
    _hasShadow = initial?.shadowColorValue != null;
    _shadowColorValue = initial?.shadowColorValue ?? 0x8A000000;
    _hasBackgroundBox = initial?.boxColorValue != null;
    _boxColorValue = initial?.boxColorValue ?? 0xCC000000;
    _boxBorderRadius = (initial != null && initial.boxBorderRadius > 0.0)
        ? initial.boxBorderRadius
        : 8.0;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  TextLayer _buildCurrentLayer() {
    final base = widget.initialLayer;
    final libraryEntry = ref.read(fontLibraryProvider).value?.entryFor(_fontFamily);
    final text = _textController.text.trim().isEmpty ? 'Your text' : _textController.text;

    return TextLayer(
      id: base?.id ?? const Uuid().v4(),
      x: base?.x ?? 0.5,
      y: base?.y ?? 0.5,
      scale: base?.scale ?? 1.0,
      rotation: base?.rotation ?? 0.0,
      zIndex: base?.zIndex ?? 0,
      isVisible: base?.isVisible ?? true,
      text: text,
      fontFamily: _fontFamily,
      isCustomFont: _fontFamily != systemDefaultFontFamily,
      customFontPath: libraryEntry?.relativePath,
      textColorValue: _textColorValue,
      fontSize: _fontSize,
      isBold: _isBold,
      isItalic: _isItalic,
      boxColorValue: _hasBackgroundBox ? _boxColorValue : null,
      boxBorderRadius: _boxBorderRadius,
      shadowColorValue: _hasShadow ? _shadowColorValue : null,
    );
  }

  void _onDone() {
    final layer = _buildCurrentLayer();
    widget.onSaved?.call(layer);
    Navigator.of(context).pop(layer);
  }

  Future<void> _chooseFont() async {
    final family = await FontPickerSheet.show(context, currentFamily: _fontFamily);
    if (family != null && mounted) setState(() => _fontFamily = family);
  }

  String _fontLabel(FontLibraryState? library) {
    if (_fontFamily == systemDefaultFontFamily) return 'Default';
    final entry = library?.entryFor(_fontFamily);
    if (entry != null) return entry.displayName;
    final name = _fontFamily.replaceFirst(FontLibraryNotifier.importedFamilyPrefix, '');
    return '$name (not installed)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final library = ref.watch(fontLibraryProvider).value;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  Expanded(
                    child: Text(
                      _isNew ? 'Add Text' : 'Edit Text',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton(
                    key: const ValueKey('text_edit_done_button'),
                    onPressed: _onDone,
                    style: FilledButton.styleFrom(minimumSize: const Size(64.0, 40.0)),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            // Live preview, rendered exactly like on the canvas.
            Container(
              key: const ValueKey('text_preview'),
              height: 120.0,
              margin: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTheme.canvasBackdrop,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TextLayerWidget(layer: _buildCurrentLayer()),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                children: [
                  TextField(
                    key: const ValueKey('text_input_field'),
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Type your text'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12.0),
                  Card(
                    child: ListTile(
                      key: const ValueKey('font_picker_row'),
                      leading: const Icon(Icons.font_download_outlined),
                      title: const Text('Font'),
                      subtitle: Text(_fontLabel(library)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _chooseFont,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _SectionLabel('Size', trailing: '${_fontSize.round()} pt'),
                  Slider(
                    key: const ValueKey('font_size_slider'),
                    value: _fontSize,
                    min: minFontSize,
                    max: maxFontSize,
                    onChanged: (value) => setState(() => _fontSize = value),
                  ),
                  Row(
                    children: [
                      FilterChip(
                        key: const ValueKey('bold_toggle_button'),
                        avatar: const Icon(Icons.format_bold_rounded),
                        label: const Text('Bold'),
                        showCheckmark: false,
                        selected: _isBold,
                        onSelected: (value) => setState(() => _isBold = value),
                      ),
                      const SizedBox(width: 8.0),
                      FilterChip(
                        key: const ValueKey('italic_toggle_button'),
                        avatar: const Icon(Icons.format_italic_rounded),
                        label: const Text('Italic'),
                        showCheckmark: false,
                        selected: _isItalic,
                        onSelected: (value) => setState(() => _isItalic = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const _SectionLabel('Color'),
                  const SizedBox(height: 8.0),
                  _ColorRow(
                    keyPrefix: 'text_color',
                    colors: paletteColors,
                    selected: _textColorValue,
                    onSelected: (value) => setState(() => _textColorValue = value),
                  ),
                  const SizedBox(height: 8.0),
                  SwitchListTile(
                    key: const ValueKey('shadow_switch'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Drop shadow'),
                    value: _hasShadow,
                    onChanged: (value) => setState(() => _hasShadow = value),
                  ),
                  SwitchListTile(
                    key: const ValueKey('background_box_switch'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Background box'),
                    value: _hasBackgroundBox,
                    onChanged: (value) => setState(() => _hasBackgroundBox = value),
                  ),
                  if (_hasBackgroundBox) ...[
                    _ColorRow(
                      keyPrefix: 'box_color',
                      colors: boxColors,
                      selected: _boxColorValue,
                      onSelected: (value) => setState(() => _boxColorValue = value),
                    ),
                    const SizedBox(height: 12.0),
                    _SectionLabel('Corner radius', trailing: '${_boxBorderRadius.round()}'),
                    Slider(
                      key: const ValueKey('box_border_radius_slider'),
                      value: _boxBorderRadius,
                      min: 0.0,
                      max: 40.0,
                      onChanged: (value) => setState(() => _boxBorderRadius = value),
                    ),
                  ],
                  if (library != null && !library.isInstalled(_fontFamily))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'This text shows in the default font until its font is installed.',
                        style: TextStyle(color: colors.error),
                      ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
        if (trailing != null)
          Text(
            trailing!,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
          ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.keyPrefix,
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  final String keyPrefix;
  final List<int> colors;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: [
        for (final color in colors)
          Semantics(
            button: true,
            selected: color == selected,
            label: 'Color',
            child: GestureDetector(
              key: ValueKey('${keyPrefix}_$color'),
              onTap: () => onSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34.0,
                height: 34.0,
                decoration: BoxDecoration(
                  color: Color(color),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == selected ? scheme.primary : scheme.outlineVariant,
                    width: color == selected ? 3.0 : 1.0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
