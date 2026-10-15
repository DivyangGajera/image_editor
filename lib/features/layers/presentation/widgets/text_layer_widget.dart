import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/layers/application/font_service.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Pure presentation widget rendering a styled [TextLayer].
///
/// Dynamically resolves typography from [fontServiceProvider], and applies
/// font size, text color, bold/italic styles, drop shadows, and background boxes.
class TextLayerWidget extends ConsumerWidget {
  const TextLayerWidget({
    super.key,
    required this.layer,
  });

  final TextLayer layer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontService = ref.watch(fontServiceProvider);

    final baseStyle = TextStyle(
      fontSize: layer.fontSize,
      color: Color(layer.textColorValue),
      fontWeight: layer.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: layer.isItalic ? FontStyle.italic : FontStyle.normal,
      shadows: layer.shadowColorValue != null
          ? <Shadow>[
              Shadow(
                color: Color(layer.shadowColorValue!),
                blurRadius: 4.0,
                offset: const Offset(2.0, 2.0),
              ),
            ]
          : null,
    );

    final resolvedStyle = fontService.getTextStyle(
      fontFamily: layer.fontFamily,
      baseStyle: baseStyle,
    );

    Widget textWidget = Text(
      layer.text,
      style: resolvedStyle,
      textAlign: TextAlign.center,
    );

    if (layer.boxColorValue != null) {
      textWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Color(layer.boxColorValue!),
          borderRadius: BorderRadius.circular(layer.boxBorderRadius),
        ),
        child: textWidget,
      );
    }

    return textWidget;
  }
}
