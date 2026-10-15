import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/application/canvas_notifier.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/canvas/presentation/widgets/canvas_layer_item_widget.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Responsive, aspect-ratio locked canvas viewport rendering canvas layers
/// ordered by stacking [zIndex].
class CanvasView extends ConsumerWidget {
  const CanvasView({
    super.key,
    required this.project,
  });

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(canvasNotifierProvider(project).notifier);
    final canvasSize = Size(project.canvasWidth, project.canvasHeight);

    // Watch layer IDs ordered by zIndex. Rebuilds only when layer count or z-indexing shifts.
    final orderedLayerIds = ref.watch(
      canvasNotifierProvider(project).select((state) {
        final sorted = List<CanvasLayer>.from(state.project.layers)
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
        return sorted.map((l) => l.id).toList();
      }),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => notifier.selectLayer(null),
          child: Container(
            color: theme.scaffoldBackgroundColor,
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: project.canvasWidth,
                height: project.canvasHeight,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 16.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background tap detector for deselecting active layer
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => notifier.selectLayer(null),
                        ),
                      ),

                      // Stacking canvas layer items
                      for (final id in orderedLayerIds)
                        CanvasLayerItemWidget(
                          key: ValueKey(id),
                          project: project,
                          layerId: id,
                          canvasSize: canvasSize,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
