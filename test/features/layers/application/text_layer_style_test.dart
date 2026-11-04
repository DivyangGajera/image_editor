import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/layers/application/text_layer_style.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('TextLayerStyle.base', () {
    test('maps every typographic field and ignores the ambient theme', () {
      const layer = TextLayer(
        id: 't',
        x: 0.5,
        y: 0.5,
        text: 'Sale',
        fontSize: 48.0,
        textColorValue: 0xFF112233,
        isBold: true,
        isItalic: true,
      );

      final style = TextLayerStyle.base(layer);

      expect(style.inherit, isFalse, reason: 'theme letter spacing/height must not leak in');
      expect(style.fontSize, 48.0);
      expect(style.color, const Color(0xFF112233));
      expect(style.fontWeight, FontWeight.bold);
      expect(style.fontStyle, FontStyle.italic);
      expect(style.height, TextLayerStyle.lineHeight);
      expect(style.letterSpacing, 0.0);
      expect(style.shadows, isNull);
    });

    test('adds the drop shadow when a shadow color is set', () {
      const layer = TextLayer(id: 't', x: 0.5, y: 0.5, text: 'Sale', shadowColorValue: 0x80000000);

      final shadow = TextLayerStyle.base(layer).shadows!.single;

      expect(shadow.color, const Color(0x80000000));
      expect(shadow.offset, TextLayerStyle.shadowOffset);
      expect(shadow.blurRadius, TextLayerStyle.shadowBlurRadius);
    });
  });
}
