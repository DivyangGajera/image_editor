import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/stickers/application/user_stickers_notifier.dart';
import 'package:image_editor/features/stickers/data/sticker_repository.dart';
import 'package:image_editor/features/stickers/data/user_sticker_repository.dart';
import 'package:image_editor/features/stickers/domain/models/models.dart';
import 'package:image_editor/features/stickers/presentation/widgets/sticker_thumbnail.dart';

/// Bottom sheet for picking a sticker: the user's own stickers (with import)
/// and the bundled categories. Returns the selection, or null if dismissed.
class StickerPickerSheet extends StatelessWidget {
  const StickerPickerSheet({super.key});

  static Future<StickerSelection?> show(BuildContext context) {
    return showModalBottomSheet<StickerSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => const StickerPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final categories = ref.watch(stickerRepositoryProvider).getCategories();

        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          // A local messenger keeps snackbars visible above the sheet.
          child: ScaffoldMessenger(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: DefaultTabController(
                length: categories.length + 1,
                child: Column(
                  children: [
                    const SizedBox(height: 12.0),
                    Container(
                      width: 32.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 8.0, 0.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Stickers',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        const Tab(key: ValueKey('tab_my_stickers'), text: 'My stickers'),
                        for (final category in categories) Tab(text: category.name),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          const _MyStickersGrid(),
                          for (final category in categories)
                            _StickerGrid(
                              itemCount: category.stickers.length,
                              itemBuilder: (context, index) {
                                final item = category.stickers[index];
                                return StickerThumbnail(
                                  key: ValueKey('sticker_thumbnail_${item.id}'),
                                  label: item.title,
                                  image: Image.asset(item.assetPath, fit: BoxFit.contain),
                                  onTap: () => Navigator.of(context)
                                      .pop(BundledStickerSelection(item)),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StickerGrid extends StatelessWidget {
  const _StickerGrid({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120.0,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.9,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

class _MyStickersGrid extends ConsumerWidget {
  const _MyStickersGrid();

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(userStickersProvider.notifier).importFromDevice();
    } on StickerImportException catch (error) {
      if (context.mounted) _showMessage(context, error.message);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, UserSticker sticker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove sticker?'),
        content: const Text(
          'It is removed from My stickers. Designs that already use it keep their copy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm_delete_sticker'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await ref.read(userStickersProvider.notifier).delete(sticker);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickers = ref.watch(userStickersProvider).value ?? const <UserSticker>[];
    final repository = ref.watch(userStickerRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: _StickerGrid(
            itemCount: stickers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return StickerThumbnail(
                  key: const ValueKey('import_sticker_tile'),
                  label: 'Import',
                  image: Icon(Icons.add_photo_alternate_outlined, size: 36.0, color: colors.primary),
                  onTap: () => _import(context, ref),
                );
              }
              final sticker = stickers[index - 1];
              return StickerThumbnail(
                key: ValueKey('user_sticker_${sticker.id}'),
                image: FutureBuilder<File>(
                  future: repository.resolve(sticker.relativePath),
                  builder: (context, snapshot) {
                    final file = snapshot.data;
                    return file == null
                        ? const SizedBox.shrink()
                        : Image.file(
                            file,
                            fit: BoxFit.contain,
                            cacheWidth: 256,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.broken_image_outlined,
                              color: colors.outline,
                            ),
                          );
                  },
                ),
                onTap: () => Navigator.of(context).pop(UserStickerSelection(sticker)),
                onLongPress: () => _confirmDelete(context, ref, sticker),
              );
            },
          ),
        ),
        if (stickers.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
            child: Text(
              'Import your logo or any PNG to reuse it in every design. '
              'Long-press a sticker to remove it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
