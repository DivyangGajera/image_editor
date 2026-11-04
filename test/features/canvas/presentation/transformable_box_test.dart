import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/canvas/presentation/widgets/transformable_box.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('TransformableBox.snapRotation', () {
    test('snaps angles close to a right angle', () {
      expect(TransformableBox.snapRotation(0.03), 0.0);
      expect(TransformableBox.snapRotation(math.pi / 2 - 0.02), closeTo(math.pi / 2, 1e-12));
      expect(TransformableBox.snapRotation(-math.pi + 0.04), closeTo(-math.pi, 1e-12));
    });

    test('leaves other angles untouched', () {
      expect(TransformableBox.snapRotation(0.3), 0.3);
      expect(TransformableBox.snapRotation(math.pi / 4), math.pi / 4);
    });
  });

  group('TransformableBox.handleTransform', () {
    test('doubling the distance from the center doubles the scale', () {
      final result = TransformableBox.handleTransform(
        startVector: const Offset(50, 50),
        currentVector: const Offset(100, 100),
        startScale: 1.5,
        startRotation: 0.0,
      );
      expect(result.scale, closeTo(3.0, 1e-9));
      expect(result.rotation, closeTo(0.0, 1e-9));
    });

    test('sweeping the handle around the center rotates by the swept angle', () {
      final result = TransformableBox.handleTransform(
        startVector: const Offset(100, 0),
        currentVector: Offset.fromDirection(0.6, 100),
        startScale: 1.0,
        startRotation: 0.2,
      );
      expect(result.scale, closeTo(1.0, 1e-9));
      expect(result.rotation, closeTo(0.8, 1e-9));
    });

    test('clamps scale and ignores a degenerate start vector', () {
      final tiny = TransformableBox.handleTransform(
        startVector: const Offset(100, 0),
        currentVector: const Offset(0.001, 0),
        startScale: 1.0,
        startRotation: 0.0,
      );
      expect(tiny.scale, TransformableBox.minScale);

      final degenerate = TransformableBox.handleTransform(
        startVector: Offset.zero,
        currentVector: const Offset(80, 80),
        startScale: 2.0,
        startRotation: 0.4,
      );
      expect(degenerate.scale, 2.0);
      expect(degenerate.rotation, 0.4);
    });
  });

  testWidgets('dragging the corner handle reports scale and rotation as one gesture',
      (tester) async {
    const layer = TextLayer(id: 't', x: 0.5, y: 0.5, text: 'Handle', fontSize: 40.0);
    var started = 0;
    var ended = 0;
    double? lastScale;

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 600,
            height: 600,
            child: Stack(
              children: [
                TransformableBox(
                  layer: layer,
                  isSelected: true,
                  canvasSize: const Size(600, 600),
                  viewScale: 1.0,
                  onSelect: () {},
                  onInteractionStart: () => started++,
                  onTransformPreview: ({x, y, scale, rotation}) => lastScale = scale,
                  onInteractionEnd: () => ended++,
                  onDelete: () {},
                  child: Text(layer.text, style: const TextStyle(fontSize: 40.0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final handle = find.byKey(const ValueKey('rotate_scale_handle'));
    expect(handle, findsOneWidget);

    final center = tester.getCenter(find.text('Handle'));
    final handleCenter = tester.getCenter(handle);
    // Drag the handle directly away from the center to twice its distance.
    final outward = handleCenter - center;
    await tester.dragFrom(handleCenter, outward);
    await tester.pump();

    expect(started, 1);
    expect(ended, 1);
    expect(lastScale, isNotNull);
    expect(lastScale!, greaterThan(1.5));
  });
}
