import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/fonts/application/font_library_notifier.dart';
import 'package:image_editor/features/fonts/application/font_resolver.dart';
import 'package:image_editor/features/layers/application/text_layer_style.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Renders a styled [TextLayer] on the canvas.
///
/// The font comes from the app's font library. If the layer's font is not
/// installed (e.g. it was deleted), the text falls back to the default font
/// and a small badge marks it until the font is downloaded or imported again.
class TextLayerWidget extends ConsumerWidget {
  const TextLayerWidget({
    super.key,
    required this.layer,
  });

  final TextLayer layer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild only when the installed fonts change, not on download progress.
    final installedFonts = ref.watch(fontLibraryProvider.select((s) => s.value?.fonts));
    final installed = installedFonts == null
        ? null
        : ref.read(fontLibraryProvider).value?.installedFamilies;

    final style = FontResolver.apply(TextLayerStyle.base(layer), layer.fontFamily, installed);

    Widget content = Text(layer.text, style: style, textAlign: TextAlign.center);

    final boxColor = layer.boxColorValue;
    if (boxColor != null) {
      content = Container(
        padding: TextLayerStyle.boxPadding,
        decoration: BoxDecoration(
          color: Color(boxColor),
          borderRadius: BorderRadius.circular(layer.boxBorderRadius),
        ),
        child: content,
      );
    }

    if (!FontResolver.isMissing(layer.fontFamily, installed)) return content;

    final badgeSize = (layer.fontSize * 0.6).clamp(12.0, 64.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        content,
        Positioned(
          top: -badgeSize / 2,
          right: -badgeSize / 2,
          child: Semantics(
            label: 'Font not installed',
            child: Container(
              key: const ValueKey('missing_font_badge'),
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: badgeSize * 0.08),
              ),
              child: Icon(
                Icons.font_download_off_rounded,
                size: badgeSize * 0.6,
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
