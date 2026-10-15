import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/layers/presentation/widgets/doodle_canvas_overlay.dart';

void main() {
  group('DoodleCanvasOverlay Widget Tests', () {
    const canvasSize = Size(500.0, 500.0);

    testWidgets('renders empty shrink box when isEnabled is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoodleCanvasOverlay(
              canvasSize: canvasSize,
              isEnabled: false,
              onDoodleFinished: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('captures pan gesture, throttles with epsilon, and emits DoodleLayer on pan end', (tester) async {
      DoodleLayer? finishedLayer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 500.0,
                height: 500.0,
                child: DoodleCanvasOverlay(
                  canvasSize: canvasSize,
                  strokeColor: Colors.cyan,
                  strokeWidth: 6.0,
                  hasGlow: true,
                  isEnabled: true,
                  onDoodleFinished: (layer) {
                    finishedLayer = layer;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(DoodleCanvasOverlay));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      // Micro-move < 3.0 px (e.g. 1.0 px)
      await gesture.moveBy(const Offset(1.0, 1.0));
      await tester.pump();

      // Move >= 3.0 px (e.g. 30.0 px, exceeding kTouchSlop)
      await gesture.moveBy(const Offset(30.0, 30.0));
      await tester.pump();

      await gesture.moveBy(const Offset(40.0, -10.0));
      await tester.pump();

      // End stroke
      await gesture.up();
      await tester.pumpAndSettle();

      expect(finishedLayer, isNotNull);
      expect(finishedLayer!.points.length, 3); // Start point + 2 significant moves
      expect(finishedLayer!.strokeWidth, 6.0);
      expect(finishedLayer!.hasGlow, isTrue);
      expect(finishedLayer!.strokeColorValue, Colors.cyan.toARGB32());

      // Normalized coordinates should be within [0.0, 1.0]
      for (final pt in finishedLayer!.points) {
        expect(pt[0], inInclusiveRange(0.0, 1.0));
        expect(pt[1], inInclusiveRange(0.0, 1.0));
      }
    });
  });
}
