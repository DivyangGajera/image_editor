import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/layers/application/font_service.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/layers/presentation/widgets/text_layer_widget.dart';
import 'package:uuid/uuid.dart';

/// Modal bottom sheet for creating or styling a [TextLayer].
///
/// Provides real-time interactive controls for text editing, Google Fonts selection,
/// font sizing, bold/italic toggles, text color, drop shadow, and background pill box styling.
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

  /// Helper displaying the modal bottom sheet and returning the configured [TextLayer].
  static Future<TextLayer?> show(
    BuildContext context, {
    TextLayer? initialLayer,
  }) {
    return showModalBottomSheet<TextLayer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TextEditSheet(initialLayer: initialLayer),
    );
  }

  @override
  ConsumerState<TextEditSheet> createState() => _TextEditSheetState();
}

class _TextEditSheetState extends ConsumerState<TextEditSheet> {
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

  static const List<int> _paletteColors = <int>[
    0xFFFFFFFF, // Pure White
    0xFF000000, // Black
    0xFFF44336, // Crimson Red
    0xFFE91E63, // Hot Pink
    0xFF9C27B0, // Vivid Purple
    0xFF3F51B5, // Indigo
    0xFF2196F3, // Dodger Blue
    0xFF00BCD4, // Cyan
    0xFF009688, // Teal
    0xFF4CAF50, // Grass Green
    0xFFFFEB3B, // Lemon Yellow
    0xFFFF9800, // Vibrant Orange
    0xFFFF5722, // Deep Coral
  ];

  static const List<int> _boxColors = <int>[
    0xCC000000, // Semi-transparent black
    0xCCFFFFFF, // Semi-transparent white
    0xFF1E293B, // Slate navy
    0xFFEF4444, // Red
    0xFF3B82F6, // Royal blue
    0xFF10B981, // Emerald green
    0xFFF59E0B, // Amber
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLayer;
    _textController = TextEditingController(text: initial?.text ?? 'Your Text Here');
    _fontFamily = initial?.fontFamily ?? 'Roboto';
    _fontSize = initial?.fontSize ?? 28.0;
    _isBold = initial?.isBold ?? false;
    _isItalic = initial?.isItalic ?? false;
    _textColorValue = initial?.textColorValue ?? 0xFFFFFFFF;
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
    return TextLayer(
      id: base?.id ?? const Uuid().v4(),
      x: base?.x ?? 0.5,
      y: base?.y ?? 0.5,
      scale: base?.scale ?? 1.0,
      rotation: base?.rotation ?? 0.0,
      zIndex: base?.zIndex ?? 0,
      isVisible: base?.isVisible ?? true,
      text: _textController.text.isEmpty ? 'Your Text Here' : _textController.text,
      fontFamily: _fontFamily,
      isCustomFont: base?.isCustomFont ?? false,
      customFontPath: base?.customFontPath,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontService = ref.watch(fontServiceProvider);
    final currentLayer = _buildCurrentLayer();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        clipBehavior: Clip.antiAlias,
        elevation: 12.0,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Drag handle pill
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10.0, bottom: 4.0),
                width: 38.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

            // Modal Header: Cancel | Title | Done
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  Text(
                    widget.initialLayer == null ? 'Add Text' : 'Edit Text',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilledButton(
                    key: const ValueKey('text_edit_done_button'),
                    onPressed: _onDone,
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1.0),

            // Scrollable Content
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                shrinkWrap: true,
                children: [
                  // Live Preview Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: TextLayerWidget(layer: currentLayer),
                  ),

                  const SizedBox(height: 16.0),

                  // Text Input
                  TextField(
                    key: const ValueKey('text_input_field'),
                    controller: _textController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Text Content',
                      hintText: 'Enter text...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 20.0),

                  // Typography Picker (Google Fonts)
                  Text(
                    'Font Family',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8.0),
                  SizedBox(
                    height: 44.0,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: FontService.availableGoogleFonts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8.0),
                      itemBuilder: (context, index) {
                        final font = FontService.availableGoogleFonts[index];
                        final isSelected = _fontFamily == font;
                        final previewStyle = fontService.getTextStyle(
                          fontFamily: font,
                          baseStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontSize: 14.0,
                          ),
                        );

                        return FilterChip(
                          key: ValueKey('font_chip_$font'),
                          selected: isSelected,
                          label: Text(font, style: previewStyle),
                          onSelected: (_) {
                            setState(() {
                              _fontFamily = font;
                            });
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20.0),

                  // Font Size Slider & Style Toggles
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Font Size',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${_fontSize.round()} pt',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Slider(
                              key: const ValueKey('font_size_slider'),
                              value: _fontSize,
                              min: 12.0,
                              max: 120.0,
                              divisions: 108,
                              onChanged: (val) {
                                setState(() {
                                  _fontSize = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      IconButton.filledTonal(
                        key: const ValueKey('bold_toggle_button'),
                        isSelected: _isBold,
                        onPressed: () {
                          setState(() {
                            _isBold = !_isBold;
                          });
                        },
                        icon: const Icon(Icons.format_bold),
                      ),
                      const SizedBox(width: 6.0),
                      IconButton.filledTonal(
                        key: const ValueKey('italic_toggle_button'),
                        isSelected: _isItalic,
                        onPressed: () {
                          setState(() {
                            _isItalic = !_isItalic;
                          });
                        },
                        icon: const Icon(Icons.format_italic),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20.0),

                  // Text Color Palette
                  Text(
                    'Text Color',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8.0),
                  SizedBox(
                    height: 40.0,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _paletteColors.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8.0),
                      itemBuilder: (context, index) {
                        final colorVal = _paletteColors[index];
                        final isSelected = _textColorValue == colorVal;

                        return GestureDetector(
                          key: ValueKey('text_color_$colorVal'),
                          onTap: () {
                            setState(() {
                              _textColorValue = colorVal;
                            });
                          },
                          child: Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: BoxDecoration(
                              color: Color(colorVal),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.white24,
                                width: isSelected ? 3.0 : 1.0,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 20.0,
                                    color: colorVal == 0xFFFFFFFF
                                        ? Colors.black
                                        : Colors.white,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20.0),

                  // Drop Shadow Toggle
                  SwitchListTile(
                    key: const ValueKey('shadow_switch'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Text Drop Shadow'),
                    value: _hasShadow,
                    onChanged: (val) {
                      setState(() {
                        _hasShadow = val;
                      });
                    },
                  ),

                  const SizedBox(height: 12.0),

                  // Background Box Toggle
                  SwitchListTile(
                    key: const ValueKey('background_box_switch'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Background Box'),
                    value: _hasBackgroundBox,
                    onChanged: (val) {
                      setState(() {
                        _hasBackgroundBox = val;
                      });
                    },
                  ),

                  if (_hasBackgroundBox) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      'Box Color',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8.0),
                    SizedBox(
                      height: 36.0,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _boxColors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8.0),
                        itemBuilder: (context, index) {
                          final colorVal = _boxColors[index];
                          final isSelected = _boxColorValue == colorVal;

                          return GestureDetector(
                            key: ValueKey('box_color_$colorVal'),
                            onTap: () {
                              setState(() {
                                _boxColorValue = colorVal;
                              });
                            },
                            child: Container(
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: Color(colorVal),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.white24,
                                  width: isSelected ? 3.0 : 1.0,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16.0,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Corner Radius', style: theme.textTheme.bodyMedium),
                        Text('${_boxBorderRadius.round()} px', style: theme.textTheme.bodySmall),
                      ],
                    ),
                    Slider(
                      key: const ValueKey('box_border_radius_slider'),
                      value: _boxBorderRadius,
                      min: 0.0,
                      max: 32.0,
                      divisions: 32,
                      onChanged: (val) {
                        setState(() {
                          _boxBorderRadius = val;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
