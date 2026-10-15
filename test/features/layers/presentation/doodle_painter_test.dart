import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/layers/presentation/widgets/doodle_painter.dart';

void main() {
  group('DoodlePainter Unit & CustomPainter Tests', () {
    const canvasSize = Size(1000.0, 1000.0);

    test('shouldRepaint returns true when layer attributes change', () {
      const layer1 = DoodleLayer(
        id: 'doodle-1',
        x: 0.5,
        y: 0.5,
        points: <List<double>>[
          <double>[0.1, 0.1],
          <double>[0.2, 0.2],
        ],
        strokeWidth: 4.0,
      );

      const painter1 = DoodlePainter(layer: layer1, canvasSize: canvasSize);

      // Same properties
      const painterSame = DoodlePainter(layer: layer1, canvasSize: canvasSize);
      expect(painter1.shouldRepaint(painterSame), isFalse);

      // Different points
      final layer2 = layer1.copyWith(
        points: <List<double>>[
          <double>[0.1, 0.1],
          <double>[0.3, 0.3],
        ],
      );
      expect(painter1.shouldRepaint(DoodlePainter(layer: layer2, canvasSize: canvasSize)), isTrue);

      // Different canvas size
      expect(painter1.shouldRepaint(const DoodlePainter(layer: layer1, canvasSize: Size(500.0, 500.0))), isTrue);

      // Different stroke width
      final layer3 = layer1.copyWith(strokeWidth: 8.0);
      expect(painter1.shouldRepaint(DoodlePainter(layer: layer3, canvasSize: canvasSize)), isTrue);

      // Different glow
      final layer4 = layer1.copyWith(hasGlow: true);
      expect(painter1.shouldRepaint(DoodlePainter(layer: layer4, canvasSize: canvasSize)), isTrue);
    });

    testWidgets('paints single point dot without crashing', (tester) async {
      const singlePointLayer = DoodleLayer(
        id: 'doodle-dot',
        x: 0.5,
        y: 0.5,
        points: <List<double>>[
          <double>[0.5, 0.5],
        ],
        strokeWidth: 6.0,
        hasGlow: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: canvasSize,
              painter: DoodlePainter(
                layer: singlePointLayer,
                canvasSize: canvasSize,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('paints multi-point smoothed Bezier path without crashing', (tester) async {
      const multiPointLayer = DoodleLayer(
        id: 'doodle-curve',
        x: 0.5,
        y: 0.5,
        points: <List<double>>[
          <double>[0.1, 0.1],
          <double>[0.2, 0.4],
          <double>[0.5, 0.3],
          <double>[0.8, 0.7],
        ],
        strokeColorValue: 0xFFFF0000,
        strokeWidth: 5.0,
        hasGlow: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: canvasSize,
              painter: DoodlePainter(
                layer: multiPointLayer,
                canvasSize: canvasSize,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('paints 2-point straight segment without crashing', (tester) async {
      const twoPointLayer = DoodleLayer(
        id: 'doodle-line',
        x: 0.5,
        y: 0.5,
        points: <List<double>>[
          <double>[0.2, 0.2],
          <double>[0.8, 0.8],
        ],
        strokeWidth: 4.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: canvasSize,
              painter: DoodlePainter(
                layer: twoPointLayer,
                canvasSize: canvasSize,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
