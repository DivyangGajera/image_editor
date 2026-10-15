import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/application/canvas_notifier.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/canvas/presentation/widgets/layer_renderer.dart';
import 'package:image_editor/features/canvas/presentation/widgets/transformable_box.dart';

/// Isolated [ConsumerWidget] for an individual canvas layer.
///
/// Uses granular `.select()` listeners on [canvasNotifierProvider] so only the active
/// layer being manipulated rebuilds during touch and drag interactions.
class CanvasLayerItemWidget extends ConsumerWidget {
  const CanvasLayerItemWidget({
    super.key,
    required this.project,
    required this.layerId,
    required this.canvasSize,
  });

  final ProjectModel project;
  final String layerId;
  final Size canvasSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuilds ONLY when this layer's selection state changes
    final isSelected = ref.watch(
      canvasNotifierProvider(project).select(
        (state) => state.selectedLayerId == layerId,
      ),
    );

    // Rebuilds ONLY when this specific layer's properties mutate
    final layer = ref.watch(
      canvasNotifierProvider(project).select(
        (state) {
          for (final l in state.project.layers) {
            if (l.id == layerId) return l;
          }
          return null;
        },
      ),
    );

    if (layer == null) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(canvasNotifierProvider(project).notifier);

    return TransformableBox(
      layer: layer,
      isSelected: isSelected,
      canvasSize: canvasSize,
      onSelect: () => notifier.selectLayer(layer.id),
      onTransformUpdate: ({
        double? x,
        double? y,
        double? scale,
        double? rotation,
        bool recordHistory = true,
      }) {
        notifier.updateLayerTransform(
          layer.id,
          x: x,
          y: y,
          scale: scale,
          rotation: rotation,
          recordHistory: recordHistory,
        );
      },
      onDelete: () => notifier.deleteLayer(layer.id),
      child: LayerRenderer(layer: layer, canvasSize: canvasSize),
    );
  }
}
