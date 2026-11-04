import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/canvas/application/canvas_coordinate_converter.dart';
import 'package:image_editor/features/canvas/application/canvas_notifier.dart';
import 'package:image_editor/features/canvas/presentation/widgets/canvas_layer_item_widget.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Responsive, aspect-ratio locked canvas viewport rendering canvas layers
/// ordered by stacking [CanvasLayer.zIndex].
///
/// Must only be shown once the project's [canvasProvider] has loaded.
class CanvasView extends ConsumerWidget {
  const CanvasView({
    super.key,
    required this.projectId,
    this.overlayBuilder,
  });

  final String projectId;

  /// Optional widget stacked above all layers, laid out in canvas units
  /// (e.g. the freehand drawing surface). Receives the canvas size.
  final Widget Function(Size canvasSize)? overlayBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = canvasProvider(projectId);
    final notifier = ref.read(provider.notifier);

    final canvasSize = ref.watch(
      provider.select((async) {
        final project = async.requireValue.project;
        return Size(project.canvasWidth, project.canvasHeight);
      }),
    );

    // Watch layer IDs ordered by zIndex. Rebuilds only when layer count or z-indexing shifts.
    final orderedLayerIds = ref.watch(
      provider.select((async) {
        final sorted = List<CanvasLayer>.from(async.requireValue.project.layers)
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
        return sorted.map((l) => l.id).toList();
      }),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewScale = CanvasCoordinateConverter.fitScale(
          viewportSize: constraints.biggest,
          canvasSize: canvasSize,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => notifier.selectLayer(null),
          child: Container(
            color: AppTheme.canvasBackdrop,
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 24.0,
                        offset: Offset(0, 6),
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
                          projectId: projectId,
                          layerId: id,
                          canvasSize: canvasSize,
                          viewScale: viewScale,
                        ),

                      if (overlayBuilder != null)
                        Positioned.fill(child: overlayBuilder!(canvasSize)),
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
