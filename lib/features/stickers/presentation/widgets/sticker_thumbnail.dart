import 'package:flutter/material.dart';
import 'package:image_editor/features/stickers/domain/models/sticker_item.dart';

/// Interactive card thumbnail rendering a sticker asset with label and tap feedback.
class StickerThumbnail extends StatelessWidget {
  const StickerThumbnail({
    super.key,
    required this.item,
    required this.onTap,
  });

  /// The sticker metadata to display.
  final StickerItem item;

  /// Callback executed when the thumbnail is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('sticker_thumbnail_${item.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: const Color(0xFF2E2E40),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  item.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.local_offer_outlined,
                      size: 36.0,
                      color: Colors.white54,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
