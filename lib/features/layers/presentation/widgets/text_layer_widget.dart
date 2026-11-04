import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/layers/application/font_service.dart';
import 'package:image_editor/features/layers/application/text_layer_style.dart';
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

    final baseStyle = TextLayerStyle.base(layer);

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
        padding: TextLayerStyle.boxPadding,
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
