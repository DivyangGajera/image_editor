import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/application/canvas_notifier.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/layers/domain/models/sticker_layer.dart';
import 'package:image_editor/features/stickers/data/sticker_repository.dart';
import 'package:image_editor/features/stickers/domain/models/sticker_category.dart';
import 'package:image_editor/features/stickers/domain/models/sticker_item.dart';
import 'package:image_editor/features/stickers/presentation/widgets/sticker_thumbnail.dart';
import 'package:uuid/uuid.dart';

/// Modal bottom sheet displaying categorized stickers and promo badges.
///
/// Selecting a sticker instantiates a new [StickerLayer] positioned at
/// canvas center with normalized coordinates (`x: 0.5, y: 0.5`).
class StickerPickerSheet extends ConsumerWidget {
  const StickerPickerSheet({
    super.key,
    this.project,
    this.onStickerSelected,
    this.defaultX = 0.5,
    this.defaultY = 0.5,
    this.defaultScale = 1.0,
  });

  /// Optional active [ProjectModel]. When provided, the instantiated
  /// [StickerLayer] is automatically added to the canvas via [CanvasNotifier].
  final ProjectModel? project;

  /// Optional callback invoked when a sticker is selected.
  final ValueChanged<StickerLayer>? onStickerSelected;

  /// Default normalized horizontal center position on canvas (defaults to 0.5).
  final double defaultX;

  /// Default normalized vertical center position on canvas (defaults to 0.5).
  final double defaultY;

  /// Default scaling multiplier (defaults to 1.0).
  final double defaultScale;

  /// Helper displaying the modal bottom sheet and returning the instantiated [StickerLayer].
  static Future<StickerLayer?> show(
    BuildContext context, {
    ProjectModel? project,
    ValueChanged<StickerLayer>? onStickerSelected,
    double defaultX = 0.5,
    double defaultY = 0.5,
    double defaultScale = 1.0,
  }) {
    return showModalBottomSheet<StickerLayer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StickerPickerSheet(
        project: project,
        onStickerSelected: onStickerSelected,
        defaultX: defaultX,
        defaultY: defaultY,
        defaultScale: defaultScale,
      ),
    );
  }

  Future<void> _handleStickerTap(BuildContext context, WidgetRef ref, StickerItem item) async {
    final layer = StickerLayer(
      id: const Uuid().v4(),
      x: defaultX,
      y: defaultY,
      scale: defaultScale,
      rotation: 0.0,
      zIndex: 0,
      isVisible: true,
      assetPath: item.assetPath,
    );

    final navigator = Navigator.of(context);
    if (project != null) {
      await ref.read(canvasNotifierProvider(project!).notifier).addLayer(layer);
    }

    onStickerSelected?.call(layer);
    if (context.mounted && navigator.canPop()) {
      navigator.pop(layer);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(stickerRepositoryProvider);
    final categories = repository.getCategories();

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Color(0xFF161622),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16.0,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: DefaultTabController(
          length: categories.length,
          child: Column(
            children: [
              const SizedBox(height: 10.0),
              // Drag handle
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              // Header title and close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      color: Color(0xFF4E95FF),
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    const Text(
                      'Stickers & Badges',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20.0),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              // Category TabBar
              TabBar(
                isScrollable: categories.length > 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                indicatorColor: const Color(0xFF4E95FF),
                indicatorWeight: 3.0,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  for (final cat in categories)
                    Tab(
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(color: Color(0xFF2E2E40), height: 1.0),
              // TabBarView with sticker grids
              Expanded(
                child: TabBarView(
                  children: [
                    for (final cat in categories)
                      _CategoryGrid(
                        category: cat,
                        onTapSticker: (item) => _handleStickerTap(context, ref, item),
                      ),
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

/// Grid rendering the stickers for a specific [StickerCategory].
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.category,
    required this.onTapSticker,
  });

  final StickerCategory category;
  final ValueChanged<StickerItem> onTapSticker;

  @override
  Widget build(BuildContext context) {
    if (category.stickers.isEmpty) {
      return const Center(
        child: Text(
          'No stickers available',
          style: TextStyle(color: Colors.white38, fontSize: 13.0),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130.0,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.95,
      ),
      itemCount: category.stickers.length,
      itemBuilder: (context, index) {
        final item = category.stickers[index];
        return StickerThumbnail(
          item: item,
          onTap: () => onTapSticker(item),
        );
      },
    );
  }
}

/// Alias for [StickerPickerSheet] matching phase specification naming.
typedef StickerPickerBottomSheet = StickerPickerSheet;
