import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/application/canvas_notifier.dart';
import 'package:image_editor/features/canvas/presentation/widgets/layer_renderer.dart';
import 'package:image_editor/features/canvas/presentation/widgets/transformable_box.dart';

/// Isolated [ConsumerWidget] for an individual canvas layer.
///
/// Uses granular `.select()` listeners on [canvasProvider] so only the active
/// layer being manipulated rebuilds during touch and drag interactions.
class CanvasLayerItemWidget extends ConsumerWidget {
  const CanvasLayerItemWidget({
    super.key,
    required this.projectId,
    required this.layerId,
    required this.canvasSize,
    required this.viewScale,
  });

  final String projectId;
  final String layerId;
  final Size canvasSize;

  /// Screen logical pixels per canvas unit.
  final double viewScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuilds ONLY when this layer's selection state changes
    final isSelected = ref.watch(
      canvasProvider(projectId).select(
        (async) => async.requireValue.selectedLayerId == layerId,
      ),
    );

    // Rebuilds ONLY when this specific layer's properties mutate
    final layer = ref.watch(
      canvasProvider(projectId).select(
        (async) {
          for (final l in async.requireValue.project.layers) {
            if (l.id == layerId) return l;
          }
          return null;
        },
      ),
    );

    // Hidden layers are not drawn and must not capture touches.
    if (layer == null || !layer.isVisible) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(canvasProvider(projectId).notifier);

    return TransformableBox(
      layer: layer,
      isSelected: isSelected,
      canvasSize: canvasSize,
      viewScale: viewScale,
      onSelect: () => notifier.selectLayer(layer.id),
      onInteractionStart: () => notifier.beginInteraction(layer.id),
      onTransformPreview: ({x, y, scale, rotation}) => notifier.previewTransform(
        layer.id,
        x: x,
        y: y,
        scale: scale,
        rotation: rotation,
      ),
      onInteractionEnd: notifier.commitInteraction,
      onDelete: () => notifier.deleteLayer(layer.id),
      child: LayerRenderer(layer: layer, canvasSize: canvasSize),
    );
  }
}
