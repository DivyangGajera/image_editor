import 'package:flutter/painting.dart';
import 'package:image_editor/features/layers/domain/models/text_layer.dart';

/// Single source of truth for how a [TextLayer] looks.
///
/// Both the on-canvas widget and the headless export use these values, so an
/// export is pixel-consistent with the editor.
abstract final class TextLayerStyle {
  /// Padding between the text and its optional background box, in canvas units.
  static const EdgeInsets boxPadding =
      EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0);

  /// Line height multiplier for multi-line text.
  static const double lineHeight = 1.2;

  static const Offset shadowOffset = Offset(2.0, 2.0);
  static const double shadowBlurRadius = 4.0;

  /// Fully specified base style for [layer], without the font family.
  ///
  /// `inherit: false` keeps the app theme (letter spacing, line height of the
  /// ambient text style) from changing how canvas text looks on screen versus
  /// in an export.
  static TextStyle base(TextLayer layer) {
    final shadowColor = layer.shadowColorValue;
    return TextStyle(
      inherit: false,
      color: Color(layer.textColorValue),
      fontSize: layer.fontSize,
      fontWeight: layer.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: layer.isItalic ? FontStyle.italic : FontStyle.normal,
      height: lineHeight,
      letterSpacing: 0.0,
      wordSpacing: 0.0,
      textBaseline: TextBaseline.alphabetic,
      shadows: shadowColor == null
          ? null
          : <Shadow>[
              Shadow(
                color: Color(shadowColor),
                blurRadius: shadowBlurRadius,
                offset: shadowOffset,
              ),
            ],
    );
  }
}
