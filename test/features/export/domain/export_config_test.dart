import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/export/domain/models/models.dart';

void main() {
  group('WatermarkConfig', () {
    test('default values are set correctly', () {
      const config = WatermarkConfig();
      expect(config.isEnabled, isFalse);
      expect(config.type, equals(WatermarkType.text));
      expect(config.text, equals('Chitred'));
      expect(config.logoAssetOrFilePath, isNull);
      expect(config.position, equals(WatermarkPosition.bottomRight));
      expect(config.opacity, equals(0.75));
      expect(config.fontSize, equals(24.0));
      expect(config.colorValue, equals(0xFFFFFFFF));
    });

    test('copyWith updates fields while preserving existing values', () {
      const config = WatermarkConfig();
      final updated = config.copyWith(
        isEnabled: true,
        text: 'Custom Stamp',
        position: WatermarkPosition.tiled,
        opacity: 0.5,
      );

      expect(updated.isEnabled, isTrue);
      expect(updated.text, equals('Custom Stamp'));
      expect(updated.position, equals(WatermarkPosition.tiled));
      expect(updated.opacity, equals(0.5));
      expect(updated.fontSize, equals(24.0));
    });

    test('equality and hashCode support', () {
      const w1 = WatermarkConfig(text: 'Watermark', opacity: 0.6);
      const w2 = WatermarkConfig(text: 'Watermark', opacity: 0.6);
      const w3 = WatermarkConfig(text: 'Other', opacity: 0.6);

      expect(w1, equals(w2));
      expect(w1.hashCode, equals(w2.hashCode));
      expect(w1, isNot(equals(w3)));
    });
  });

  group('ExportConfig', () {
    test('default values are initialized properly', () {
      const config = ExportConfig();
      expect(config.format, equals(ExportFormat.png));
      expect(config.width, equals(1080.0));
      expect(config.height, equals(1080.0));
      expect(config.jpegQuality, equals(95));
      expect(config.watermark.isEnabled, isFalse);
    });

    test('copyWith updates specified fields', () {
      const config = ExportConfig();
      final updated = config.copyWith(
        format: ExportFormat.jpeg,
        jpegQuality: 85,
        width: 1920.0,
      );

      expect(updated.format, equals(ExportFormat.jpeg));
      expect(updated.jpegQuality, equals(85));
      expect(updated.width, equals(1920.0));
      expect(updated.height, equals(1080.0));
    });

    test('equality and hashCode support', () {
      const e1 = ExportConfig(format: ExportFormat.jpeg, jpegQuality: 90);
      const e2 = ExportConfig(format: ExportFormat.jpeg, jpegQuality: 90);
      const e3 = ExportConfig(format: ExportFormat.png, jpegQuality: 90);

      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
      expect(e1, isNot(equals(e3)));
    });
  });
}
