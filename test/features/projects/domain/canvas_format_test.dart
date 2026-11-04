import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/projects/domain/canvas_format.dart';

void main() {
  test('presets have the documented sizes', () {
    expect(CanvasFormat.square.size, const Size(1080, 1080));
    expect(CanvasFormat.portrait.size, const Size(1080, 1350));
    expect(CanvasFormat.story.size, const Size(1080, 1920));
    expect(CanvasFormat.landscape.size, const Size(1920, 1080));
  });

  test('isValidCustomSize enforces the allowed range on both sides', () {
    expect(CanvasFormat.isValidCustomSize(200, 4096), isTrue);
    expect(CanvasFormat.isValidCustomSize(199, 1000), isFalse);
    expect(CanvasFormat.isValidCustomSize(1000, 4097), isFalse);
  });

  group('sizeForPhoto', () {
    test('keeps the photo aspect ratio with a 1080 short edge', () {
      expect(CanvasFormat.sizeForPhoto(const Size(2048, 1536)), const Size(1440, 1080));
      expect(CanvasFormat.sizeForPhoto(const Size(1000, 2000)), const Size(1080, 2160));
    });

    test('caps very long panoramas at the maximum side', () {
      final size = CanvasFormat.sizeForPhoto(const Size(8000, 1000));
      expect(size.width, 4096);
      expect(size.height, 512);
    });
  });
}
