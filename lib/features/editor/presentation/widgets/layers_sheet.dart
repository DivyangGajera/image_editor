import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/application/canvas_notifier.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Bottom sheet listing the project's layers, topmost first.
///
/// Drag the handle to reorder, toggle visibility with the eye, and tap a row
/// to select that layer on the canvas.
class LayersSheet extends ConsumerWidget {
  const LayersSheet({super.key, required this.projectId});

  final String projectId;

  static Future<void> show(BuildContext context, String projectId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LayersSheet(projectId: projectId),
    );
  }

  /// Human-readable name for a layer row.
  static String labelFor(CanvasLayer layer) {
    if (layer is TextLayer) {
      final firstLine = layer.text.split('\n').first.trim();
      return firstLine.isEmpty ? 'Text' : firstLine;
    }
    if (layer is ImageLayer) return 'Photo';
    if (layer is StickerLayer) return 'Sticker';
    if (layer is DoodleLayer) return 'Drawing';
    return 'Layer';
  }

  /// Rows list layers top-first while the layer list is bottom-first
  /// (index == zIndex). Converts a row move into layer-list indices.
  static (int from, int to) layerIndicesForRowMove({
    required int oldRow,
    required int newRow,
    required int layerCount,
  }) {
    final last = layerCount - 1;
    return (last - oldRow, last - newRow);
  }

  static IconData iconFor(CanvasLayer layer) {
    if (layer is TextLayer) return Icons.title_rounded;
    if (layer is ImageLayer) return Icons.image_outlined;
    if (layer is StickerLayer) return Icons.sell_outlined;
    return Icons.gesture_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final canvas = ref.watch(canvasProvider(projectId)).value;
    if (canvas == null) return const SizedBox.shrink();

    final notifier = ref.read(canvasProvider(projectId).notifier);
    // Stored bottom-to-top (list index == zIndex); show the top layer first.
    final layers = canvas.project.layers;
    final topFirst = layers.reversed.toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 8.0),
              child: Text('Layers', style: Theme.of(context).textTheme.titleLarge),
            ),
            if (topFirst.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No layers yet. Add a photo, text or sticker.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              )
            else
              Flexible(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: topFirst.length,
                  onReorderItem: (oldRow, newRow) {
                    final (from, to) = layerIndicesForRowMove(
                      oldRow: oldRow,
                      newRow: newRow,
                      layerCount: layers.length,
                    );
                    notifier.reorderLayer(from, to);
                  },
                  itemBuilder: (context, index) {
                    final layer = topFirst[index];
                    final selected = layer.id == canvas.selectedLayerId;
                    return ListTile(
                      key: ValueKey('layer_row_${layer.id}'),
                      selected: selected,
                      selectedTileColor: colors.primaryContainer.withValues(alpha: 0.5),
                      leading: Icon(
                        iconFor(layer),
                        color: layer.isVisible ? null : colors.outline,
                      ),
                      title: Text(
                        labelFor(layer),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: layer.isVisible ? null : colors.outline,
                        ),
                      ),
                      onTap: layer.isVisible
                          ? () {
                              notifier.selectLayer(layer.id);
                              Navigator.of(context).pop();
                            }
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: ValueKey('layer_lock_${layer.id}'),
                            tooltip: layer.isLocked ? 'Unlock layer' : 'Lock layer',
                            color: layer.isLocked ? colors.primary : null,
                            icon: Icon(layer.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded),
                            onPressed: () => notifier.toggleLock(layer.id),
                          ),
                          IconButton(
                            key: ValueKey('layer_visibility_${layer.id}'),
                            tooltip: layer.isVisible ? 'Hide layer' : 'Show layer',
                            icon: Icon(
                              layer.isVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => notifier.toggleVisibility(layer.id),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.drag_handle_rounded),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
