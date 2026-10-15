import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/application/canvas_notifier.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/images/presentation/widgets/filter_selector_bar.dart';
import 'package:image_editor/features/layers/domain/models/image_layer.dart';

/// Contextual bottom editing toolbar displayed when an [ImageLayer] is selected on the canvas.
///
/// Enables flipping the image horizontally and switching GPU-accelerated color filters.
class ImageEditingToolbar extends ConsumerWidget {
  const ImageEditingToolbar({
    super.key,
    required this.layer,
    required this.project,
    this.onLayerChanged,
  });

  /// The active image layer being configured.
  final ImageLayer layer;

  /// The active project model session.
  final ProjectModel project;

  /// Optional notification callback when layer properties change.
  final ValueChanged<ImageLayer>? onLayerChanged;

  void _toggleFlip(WidgetRef ref) {
    final updated = layer.copyWith(
      isFlippedHorizontally: !layer.isFlippedHorizontally,
    );
    ref.read(canvasNotifierProvider(project).notifier).updateLayer(updated);
    onLayerChanged?.call(updated);
  }

  void _selectFilter(WidgetRef ref, String? filterId) {
    final updated = layer.copyWith(
      activeFilter: filterId,
      clearActiveFilter: filterId == null,
    );
    ref.read(canvasNotifierProvider(project).notifier).updateLayer(updated);
    onLayerChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        border: Border(
          top: BorderSide(
            color: Color(0xFF2E2E40),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter carousel
          FilterSelectorBar(
            selectedFilterId: layer.activeFilter,
            onFilterSelected: (filterId) => _selectFilter(ref, filterId),
          ),
          const SizedBox(height: 8.0),
          const Divider(color: Color(0xFF2E2E40), height: 1.0),
          const SizedBox(height: 6.0),
          // Action controls: Horizontal Flip toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('flip_horizontal_button'),
                  onPressed: () => _toggleFlip(ref),
                  icon: Icon(
                    Icons.flip,
                    size: 18.0,
                    color: layer.isFlippedHorizontally
                        ? const Color(0xFF4E95FF)
                        : Colors.white70,
                  ),
                  label: Text(
                    'Flip Horizontally',
                    style: TextStyle(
                      color: layer.isFlippedHorizontally
                          ? const Color(0xFF4E95FF)
                          : Colors.white70,
                      fontSize: 12.0,
                      fontWeight: layer.isFlippedHorizontally
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: layer.isFlippedHorizontally
                        ? const Color(0xFF4E95FF).withAlpha(38)
                        : const Color(0xFF1E1E2C),
                    side: BorderSide(
                      color: layer.isFlippedHorizontally
                          ? const Color(0xFF4E95FF)
                          : const Color(0xFF2E2E40),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
