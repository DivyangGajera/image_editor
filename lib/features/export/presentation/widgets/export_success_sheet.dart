import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/export/application/gallery_saver.dart';

/// Confirms a finished export with a preview and a shortcut to the gallery.
class ExportSuccessSheet extends ConsumerWidget {
  const ExportSuccessSheet({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  static Future<void> show(BuildContext context, Uint8List imageBytes) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExportSuccessSheet(imageBytes: imageBytes),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 220.0,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTheme.canvasBackdrop,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Image.memory(imageBytes, fit: BoxFit.contain, cacheHeight: 600),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: colors.primary),
                const SizedBox(width: 8.0),
                Text('Saved to Gallery', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              'Find it in the ${GalGallerySaver.album} album.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20.0),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('open_gallery'),
                    onPressed: () => ref.read(gallerySaverProvider).openGallery(),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Open Gallery'),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('export_done'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
