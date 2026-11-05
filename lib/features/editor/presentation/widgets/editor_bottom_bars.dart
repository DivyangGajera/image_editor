import 'package:flutter/material.dart';
import 'package:image_editor/features/editor/presentation/widgets/tool_button.dart';
import 'package:image_editor/features/images/presentation/widgets/filter_selector_bar.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Undo, Redo and Layers: shown first in every editor tool row, so they are
/// always one tap away whatever the user is doing.
class EditorQuickActions {
  const EditorQuickActions({required this.onUndo, required this.onRedo, required this.onLayers});

  /// Null disables the button (nothing to undo / redo).
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onLayers;
}

/// Shared shell for the editor's bottom bars: surface color, top divider and a
/// horizontally scrollable row that starts with the [EditorQuickActions].
class _BarShell extends StatelessWidget {
  const _BarShell({required this.quick, required this.children, this.top, this.leading});

  final EditorQuickActions quick;
  final List<Widget> children;
  final Widget? top;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (top != null) ...[
              const SizedBox(height: 8.0),
              top!,
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  if (leading != null) ...[
                    const SizedBox(width: 4.0),
                    leading!,
                    SizedBox(
                      height: 40.0,
                      child: VerticalDivider(color: colors.outlineVariant, width: 12.0),
                    ),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('editor_tool_row'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          ToolButton(
                            key: const ValueKey('editor_undo'),
                            icon: Icons.undo_rounded,
                            label: 'Undo',
                            onPressed: quick.onUndo,
                          ),
                          ToolButton(
                            key: const ValueKey('editor_redo'),
                            icon: Icons.redo_rounded,
                            label: 'Redo',
                            onPressed: quick.onRedo,
                          ),
                          ToolButton(
                            key: const ValueKey('editor_layers'),
                            icon: Icons.layers_outlined,
                            label: 'Layers',
                            onPressed: quick.onLayers,
                          ),
                          SizedBox(
                            height: 40.0,
                            child: VerticalDivider(color: colors.outlineVariant, width: 16.0),
                          ),
                          ...children,
                        ],
                      ),
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

/// Tools shown when no layer is selected: add content to the canvas.
class MainToolBar extends StatelessWidget {
  const MainToolBar({
    super.key,
    required this.quick,
    required this.onAddPhoto,
    required this.onAddText,
    required this.onAddSticker,
    required this.onDraw,
    required this.onBackground,
  });

  final EditorQuickActions quick;
  final VoidCallback? onBackground;
  final VoidCallback? onAddPhoto;
  final VoidCallback? onAddText;
  final VoidCallback? onAddSticker;
  final VoidCallback? onDraw;

  @override
  Widget build(BuildContext context) {
    return _BarShell(
      quick: quick,
      children: [
        ToolButton(
          key: const ValueKey('tool_photo'),
          icon: Icons.add_photo_alternate_outlined,
          label: 'Photo',
          onPressed: onAddPhoto,
        ),
        ToolButton(
          key: const ValueKey('tool_text'),
          icon: Icons.title_rounded,
          label: 'Text',
          onPressed: onAddText,
        ),
        ToolButton(
          key: const ValueKey('tool_sticker'),
          icon: Icons.sell_outlined,
          label: 'Sticker',
          onPressed: onAddSticker,
        ),
        ToolButton(
          key: const ValueKey('tool_draw'),
          icon: Icons.gesture_rounded,
          label: 'Draw',
          onPressed: onDraw,
        ),
        ToolButton(
          key: const ValueKey('tool_background'),
          icon: Icons.format_color_fill_rounded,
          label: 'Background',
          onPressed: onBackground,
        ),
      ],
    );
  }
}

/// Actions for the selected layer, adapted to its type.
class LayerContextBar extends StatelessWidget {
  const LayerContextBar({
    super.key,
    required this.quick,
    required this.layer,
    required this.isFilterStripOpen,
    required this.isBusy,
    required this.onDeselect,
    required this.onDuplicate,
    required this.onToggleLock,
    required this.onBringToFront,
    required this.onSendToBack,
    required this.onDelete,
    required this.onToggleFilters,
    required this.onFilterSelected,
    required this.onFlip,
    required this.onRemoveBackground,
    required this.onEditText,
    required this.onCrop,
    required this.onResetCrop,
  });

  final EditorQuickActions quick;
  final CanvasLayer layer;
  final bool isFilterStripOpen;

  /// Disables long-running actions while one is in progress.
  final bool isBusy;

  final VoidCallback onDeselect;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleLock;
  final VoidCallback onBringToFront;
  final VoidCallback onSendToBack;
  final VoidCallback onDelete;
  final VoidCallback onToggleFilters;
  final ValueChanged<String?> onFilterSelected;
  final VoidCallback onFlip;
  final VoidCallback onRemoveBackground;
  final VoidCallback onEditText;
  final VoidCallback onCrop;
  final VoidCallback onResetCrop;

  @override
  Widget build(BuildContext context) {
    final current = layer;
    final typeTools = <Widget>[
      if (current is ImageLayer) ...[
        ToolButton(
          key: const ValueKey('ctx_filters'),
          icon: Icons.auto_awesome_outlined,
          label: 'Filters',
          isActive: isFilterStripOpen,
          onPressed: onToggleFilters,
        ),
        ToolButton(
          key: const ValueKey('ctx_crop'),
          icon: Icons.crop_rounded,
          label: 'Crop',
          onPressed: onCrop,
        ),
        if (current.isCropped)
          ToolButton(
            key: const ValueKey('ctx_reset_crop'),
            icon: Icons.crop_free_rounded,
            label: 'Uncrop',
            onPressed: onResetCrop,
          ),
        ToolButton(
          key: const ValueKey('ctx_flip'),
          icon: Icons.flip_rounded,
          label: 'Flip',
          onPressed: onFlip,
        ),
        ToolButton(
          key: const ValueKey('ctx_remove_bg'),
          icon: Icons.person_remove_alt_1_outlined,
          label: 'Remove BG',
          onPressed: isBusy ? null : onRemoveBackground,
        ),
      ],
      if (current is TextLayer)
        ToolButton(
          key: const ValueKey('ctx_edit_text'),
          icon: Icons.edit_outlined,
          label: 'Edit',
          onPressed: onEditText,
        ),
    ];

    return _BarShell(
      quick: quick,
      top: current is ImageLayer && isFilterStripOpen
          ? FilterSelectorBar(
              selectedFilterId: current.activeFilter,
              onFilterSelected: onFilterSelected,
            )
          : null,
      leading: IconButton(
        key: const ValueKey('ctx_deselect'),
        tooltip: 'Done',
        icon: const Icon(Icons.check_rounded),
        onPressed: onDeselect,
      ),
      children: [
        ...typeTools,
        ToolButton(
          key: const ValueKey('ctx_lock'),
          icon: current.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
          label: current.isLocked ? 'Unlock' : 'Lock',
          isActive: current.isLocked,
          onPressed: onToggleLock,
        ),
        ToolButton(
          key: const ValueKey('ctx_duplicate'),
          icon: Icons.copy_all_outlined,
          label: 'Duplicate',
          onPressed: onDuplicate,
        ),
        ToolButton(
          key: const ValueKey('ctx_front'),
          icon: Icons.flip_to_front_rounded,
          label: 'To front',
          onPressed: onBringToFront,
        ),
        ToolButton(
          key: const ValueKey('ctx_back'),
          icon: Icons.flip_to_back_rounded,
          label: 'To back',
          onPressed: onSendToBack,
        ),
        ToolButton(
          key: const ValueKey('ctx_delete'),
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          isDestructive: true,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

/// Brush settings shown while drawing.
class DrawToolBar extends StatelessWidget {
  const DrawToolBar({
    super.key,
    required this.quick,
    required this.colorValue,
    required this.strokeWidth,
    required this.minStrokeWidth,
    required this.maxStrokeWidth,
    required this.hasGlow,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onToggleGlow,
    required this.onDone,
  });

  /// Brush palette (ARGB).
  static const List<int> palette = <int>[
    0xFFEF4444,
    0xFFF97316,
    0xFFFACC15,
    0xFF22C55E,
    0xFF06B6D4,
    0xFF3B82F6,
    0xFF8B5CF6,
    0xFFEC4899,
    0xFFFFFFFF,
    0xFF111827,
  ];

  final EditorQuickActions quick;
  final int colorValue;
  final double strokeWidth;
  final double minStrokeWidth;
  final double maxStrokeWidth;
  final bool hasGlow;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onToggleGlow;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _BarShell(
      quick: quick,
      top: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Icon(Icons.line_weight_rounded, color: colors.onSurfaceVariant),
            Expanded(
              child: Slider(
                key: const ValueKey('draw_width_slider'),
                value: strokeWidth,
                min: minStrokeWidth,
                max: maxStrokeWidth,
                label: strokeWidth.round().toString(),
                divisions: (maxStrokeWidth - minStrokeWidth).round(),
                onChanged: onStrokeWidthChanged,
              ),
            ),
            FilterChip(
              key: const ValueKey('draw_glow_chip'),
              label: const Text('Glow'),
              selected: hasGlow,
              onSelected: (_) => onToggleGlow(),
            ),
          ],
        ),
      ),
      leading: FilledButton(
        key: const ValueKey('draw_done'),
        onPressed: onDone,
        style: FilledButton.styleFrom(minimumSize: const Size(64.0, 40.0)),
        child: const Text('Done'),
      ),
      children: [
        for (final color in palette)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Semantics(
              button: true,
              selected: color == colorValue,
              label: 'Brush color',
              child: GestureDetector(
                key: ValueKey('draw_color_${color.toRadixString(16)}'),
                onTap: () => onColorChanged(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color == colorValue ? colors.primary : colors.outlineVariant,
                      width: color == colorValue ? 3.0 : 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
