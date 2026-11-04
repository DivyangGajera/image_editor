import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/layers/application/doodle_geometry.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('DoodleGeometry.fromCanvasPoints', () {
    test('centers the layer on the stroke bounding box and makes points relative', () {
      final layer = DoodleGeometry.fromCanvasPoints(
        id: 'd1',
        canvasPoints: <List<double>>[
          <double>[0.2, 0.6],
          <double>[0.4, 0.5],
          <double>[0.3, 0.8],
        ],
        strokeColorValue: 0xFF000000,
        strokeWidth: 6.0,
        hasGlow: false,
      );

      expect(layer.x, closeTo(0.3, 1e-12));
      expect(layer.y, closeTo(0.65, 1e-12));
      expect(layer.points[0][0], closeTo(0.0, 1e-12));
      expect(layer.points[0][1], closeTo(0.1, 1e-12));
      expect(layer.points[1][0], closeTo(0.2, 1e-12));
      expect(layer.points[1][1], closeTo(0.0, 1e-12));
      expect(layer.points[2][1], closeTo(0.3, 1e-12));
    });

    test('rejects an empty stroke', () {
      expect(
        () => DoodleGeometry.fromCanvasPoints(
          id: 'd',
          canvasPoints: const <List<double>>[],
          strokeColorValue: 0,
          strokeWidth: 4.0,
          hasGlow: false,
        ),
        throwsArgumentError,
      );
    });
  });

  group('DoodleGeometry.localSize', () {
    test('spans the stroke plus stroke padding on every side', () {
      const layer = DoodleLayer(
        id: 'd',
        x: 0.5,
        y: 0.5,
        strokeWidth: 10.0,
        points: <List<double>>[
          <double>[0.0, 0.0],
          <double>[0.5, 0.25],
        ],
      );

      final size = DoodleGeometry.localSize(layer, const Size(1000, 800));

      expect(size.width, 500.0 + 10.0);
      expect(size.height, 200.0 + 10.0);
    });

    test('reserves extra room for the glow effect', () {
      const plain = DoodleLayer(
        id: 'd',
        x: 0.5,
        y: 0.5,
        strokeWidth: 4.0,
        points: <List<double>>[
          <double>[0.0, 0.0],
        ],
      );
      final glowing = plain.copyWith(hasGlow: true);

      expect(DoodleGeometry.padding(plain), 2.0);
      expect(DoodleGeometry.padding(glowing), 2.0 + DoodleGeometry.glowExtent);
    });
  });
}
