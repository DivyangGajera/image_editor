import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/collage/domain/models/models.dart';

void main() {
  group('CollageConfig', () {
    test('default configuration parameters are set correctly', () {
      const config = CollageConfig();

      expect(config.layoutType, equals(CollageLayoutType.gridMatrix));
      expect(config.rows, equals(2));
      expect(config.cols, equals(2));
      expect(config.spacing, equals(8.0));
      expect(config.borderWidth, equals(4.0));
      expect(config.borderColorValue, equals(0xFFFFFFFF));
      expect(config.outerMargin, equals(16.0));
      expect(config.canvasWidth, equals(1080.0));
      expect(config.canvasHeight, equals(1080.0));
    });

    test('copyWith updates specified fields while keeping others unchanged', () {
      const config = CollageConfig();
      final updated = config.copyWith(
        layoutType: CollageLayoutType.horizontalStrip,
        borderWidth: 12.0,
        borderColorValue: 0xFFFFD700,
        outerMargin: 24.0,
      );

      expect(updated.layoutType, equals(CollageLayoutType.horizontalStrip));
      expect(updated.borderWidth, equals(12.0));
      expect(updated.borderColorValue, equals(0xFFFFD700));
      expect(updated.outerMargin, equals(24.0));
      expect(updated.spacing, equals(8.0));
      expect(updated.canvasWidth, equals(1080.0));
    });

    test('value equality and hashCode behavior', () {
      const config1 = CollageConfig(
        layoutType: CollageLayoutType.verticalStrip,
        spacing: 10.0,
      );
      const config2 = CollageConfig(
        layoutType: CollageLayoutType.verticalStrip,
        spacing: 10.0,
      );
      const config3 = CollageConfig(
        layoutType: CollageLayoutType.horizontalStrip,
        spacing: 10.0,
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1, isNot(equals(config3)));
    });
  });

  group('CollageCell', () {
    test('stores geometry and source image path correctly', () {
      const cell = CollageCell(
        x: 0.25,
        y: 0.5,
        width: 500.0,
        height: 1000.0,
        zIndex: 1,
        sourceImagePath: '/path/to/img.png',
      );

      expect(cell.x, equals(0.25));
      expect(cell.y, equals(0.5));
      expect(cell.width, equals(500.0));
      expect(cell.height, equals(1000.0));
      expect(cell.zIndex, equals(1));
      expect(cell.sourceImagePath, equals('/path/to/img.png'));

      final updated = cell.copyWith(zIndex: 2);
      expect(updated.zIndex, equals(2));
      expect(updated.x, equals(0.25));
    });

    test('value equality and hashCode behavior', () {
      const cell1 = CollageCell(
        x: 0.5,
        y: 0.5,
        width: 200,
        height: 200,
        zIndex: 0,
        sourceImagePath: 'a.png',
      );
      const cell2 = CollageCell(
        x: 0.5,
        y: 0.5,
        width: 200,
        height: 200,
        zIndex: 0,
        sourceImagePath: 'a.png',
      );

      expect(cell1, equals(cell2));
      expect(cell1.hashCode, equals(cell2.hashCode));
    });
  });
}
