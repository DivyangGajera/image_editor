import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/layers/application/layer_placement.dart';

void main() {
  group('LayerPlacement.fitScale', () {
    test('fits a large photo into 70% of the limiting canvas dimension', () {
      expect(
        LayerPlacement.fitScale(
          contentSize: const Size(2048, 1536),
          canvasSize: const Size(1080, 1920),
        ),
        closeTo(1080 * 0.7 / 2048, 1e-9),
      );
      expect(
        LayerPlacement.fitScale(
          contentSize: const Size(1000, 2000),
          canvasSize: const Size(1080, 1080),
        ),
        closeTo(1080 * 0.7 / 2000, 1e-9),
      );
    });

    test('never enlarges content beyond its natural size', () {
      expect(
        LayerPlacement.fitScale(
          contentSize: const Size(100, 100),
          canvasSize: const Size(1080, 1080),
        ),
        1.0,
      );
    });

    test('returns 1.0 for empty sizes', () {
      expect(
        LayerPlacement.fitScale(contentSize: Size.zero, canvasSize: const Size(1080, 1080)),
        1.0,
      );
    });
  });

  group('LayerPlacement.widthScale', () {
    test('sizes a sticker to 35% of the canvas width, enlarging if needed', () {
      expect(
        LayerPlacement.widthScale(contentWidth: 200, canvasWidth: 1080),
        closeTo(1080 * 0.35 / 200, 1e-9),
      );
    });
  });
  group('LayerPlacement.textScale', () {
    test('is 3x on a 1080-wide canvas', () {
      expect(LayerPlacement.textScale(1080), 3.0);
      expect(LayerPlacement.textScale(0), 1.0);
    });
  });
}
