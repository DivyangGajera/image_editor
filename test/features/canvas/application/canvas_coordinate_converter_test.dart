import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/canvas/application/canvas_coordinate_converter.dart';

void main() {
  group('CanvasCoordinateConverter', () {
    const canvasSize = Size(1000, 1000); // 1:1 aspect ratio

    group('calculateFittedCanvasRect', () {
      test('centers square canvas on landscape viewport with left/right letterboxing', () {
        const viewportSize = Size(2000, 1000);
        final rect = CanvasCoordinateConverter.calculateFittedCanvasRect(
          viewportSize: viewportSize,
          canvasSize: canvasSize,
        );

        expect(rect.left, 500.0);
        expect(rect.top, 0.0);
        expect(rect.width, 1000.0);
        expect(rect.height, 1000.0);
      });

      test('centers square canvas on portrait viewport with top/bottom letterboxing', () {
        const viewportSize = Size(1000, 2000);
        final rect = CanvasCoordinateConverter.calculateFittedCanvasRect(
          viewportSize: viewportSize,
          canvasSize: canvasSize,
        );

        expect(rect.left, 0.0);
        expect(rect.top, 500.0);
        expect(rect.width, 1000.0);
        expect(rect.height, 1000.0);
      });

      test('returns zero rect for empty canvas or viewport', () {
        expect(
          CanvasCoordinateConverter.calculateFittedCanvasRect(
            viewportSize: Size.zero,
            canvasSize: canvasSize,
          ),
          Rect.zero,
        );
        expect(
          CanvasCoordinateConverter.calculateFittedCanvasRect(
            viewportSize: const Size(800, 600),
            canvasSize: Size.zero,
          ),
          Rect.zero,
        );
      });
    });

    group('screenToCanvasNormalized', () {
      const viewportSize = Size(2000, 1000); // letterbox: dx = 500, dy = 0, width = 1000, height = 1000

      test('converts screen center to (0.5, 0.5)', () {
        const screenCenter = Offset(1000, 500);
        final normalized = CanvasCoordinateConverter.screenToCanvasNormalized(
          screenOffset: screenCenter,
          viewportSize: viewportSize,
          canvasSize: canvasSize,
        );

        expect(normalized.dx, closeTo(0.5, 0.0001));
        expect(normalized.dy, closeTo(0.5, 0.0001));
      });

      test('converts top-left canvas corner to (0.0, 0.0)', () {
        const screenTopLeft = Offset(500, 0);
        final normalized = CanvasCoordinateConverter.screenToCanvasNormalized(
          screenOffset: screenTopLeft,
          viewportSize: viewportSize,
          canvasSize: canvasSize,
        );

        expect(normalized.dx, closeTo(0.0, 0.0001));
        expect(normalized.dy, closeTo(0.0, 0.0001));
      });

      test('converts bottom-right canvas corner to (1.0, 1.0)', () {
        const screenBottomRight = Offset(1500, 1000);
        final normalized = CanvasCoordinateConverter.screenToCanvasNormalized(
          screenOffset: screenBottomRight,
          viewportSize: viewportSize,
          canvasSize: canvasSize,
        );

        expect(normalized.dx, closeTo(1.0, 0.0001));
        expect(normalized.dy, closeTo(1.0, 0.0001));
      });
    });

    group('canvasNormalizedToScreen', () {
      const viewportSize = Size(1000, 2000); // letterbox: dx = 0, dy = 500, width = 1000, height = 1000

      test('maps (0.5, 0.5) to viewport center', () {
        final screen = CanvasCoordinateConverter.canvasNormalizedToScreen(
          normalizedOffset: const Offset(0.5, 0.5),
          viewportSize: viewportSize,
          canvasSize: canvasSize,
        );

        expect(screen.dx, closeTo(500.0, 0.0001));
        expect(screen.dy, closeTo(1000.0, 0.0001));
      });

      test('bi-directional round-trip matches original coordinates', () {
        const originalNormalized = Offset(0.25, 0.75);
        final screen = CanvasCoordinateConverter.canvasNormalizedToScreen(
          normalizedOffset: originalNormalized,
          viewportSize: viewportSize,
          canvasSize: canvasSize,
        );
        final backToNormalized = CanvasCoordinateConverter.screenToCanvasNormalized(
          screenOffset: screen,
          viewportSize: viewportSize,
          canvasSize: canvasSize,
        );

        expect(backToNormalized.dx, closeTo(originalNormalized.dx, 0.0001));
        expect(backToNormalized.dy, closeTo(originalNormalized.dy, 0.0001));
      });
    });

    group('isWithinCanvas', () {
      const viewportSize = Size(2000, 1000); // canvas is x: 500..1500, y: 0..1000

      test('returns true when point is inside canvas', () {
        expect(
          CanvasCoordinateConverter.isWithinCanvas(
            screenOffset: const Offset(1000, 500),
            viewportSize: viewportSize,
            canvasSize: canvasSize,
          ),
          isTrue,
        );
      });

      test('returns false when point is in letterboxed margin', () {
        expect(
          CanvasCoordinateConverter.isWithinCanvas(
            screenOffset: const Offset(200, 500), // Left margin
            viewportSize: viewportSize,
            canvasSize: canvasSize,
          ),
          isFalse,
        );
        expect(
          CanvasCoordinateConverter.isWithinCanvas(
            screenOffset: const Offset(1800, 500), // Right margin
            viewportSize: viewportSize,
            canvasSize: canvasSize,
          ),
          isFalse,
        );
      });
    });
  });
}
