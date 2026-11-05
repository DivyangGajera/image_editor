import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/features/segmentation/application/pixel_cutout_processor.dart';

void main() {
  group('PixelCutoutProcessor', () {
    late Uint8List testImageBytes;

    setUp(() {
      // Create a 4x4 RGBA test image filled with solid red (255, 0, 0, 255)
      final image = img.Image(width: 4, height: 4, numChannels: 4);
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
          image.setPixelRgba(x, y, 255, 0, 0, 255);
        }
      }
      testImageBytes = Uint8List.fromList(img.encodePng(image));
    });

    test('zeros alpha for confidences below threshold (< 0.7)', () async {
      const processor = PixelCutoutProcessor();

      // Top half background (0.1 confidence), bottom half foreground (0.9 confidence)
      final mask = <double>[
        0.1, 0.1, 0.1, 0.1,
        0.2, 0.2, 0.2, 0.2,
        0.95, 0.95, 0.95, 0.95,
        1.0, 1.0, 1.0, 1.0,
      ];

      final resultBytes = await processor.processCutout(
        CutoutProcessingParams(
          imageBytes: testImageBytes,
          maskConfidences: mask,
          maskWidth: 4,
          maskHeight: 4,
          confidenceThreshold: 0.7,
          smoothEdges: false,
        ),
      );

      final resultImage = img.decodePng(resultBytes);
      expect(resultImage, isNotNull);
      expect(resultImage!.width, equals(4));
      expect(resultImage.height, equals(4));

      // Top row pixels should have alpha == 0
      for (int x = 0; x < 4; x++) {
        expect(resultImage.getPixel(x, 0).a, equals(0));
        expect(resultImage.getPixel(x, 1).a, equals(0));
      }

      // Bottom row pixels should have alpha > 0
      for (int x = 0; x < 4; x++) {
        expect(resultImage.getPixel(x, 3).a, greaterThan(0));
      }
    });

    test('smooths transition boundaries when smoothEdges is true', () async {
      const processor = PixelCutoutProcessor();

      // Mask with transition boundary
      final mask = <double>[
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.75, 0.75, 0.0,
        0.0, 0.85, 0.85, 0.0,
        0.0, 0.0, 0.0, 0.0,
      ];

      final resultBytes = await processor.processCutout(
        CutoutProcessingParams(
          imageBytes: testImageBytes,
          maskConfidences: mask,
          maskWidth: 4,
          maskHeight: 4,
          confidenceThreshold: 0.7,
          smoothEdges: true,
        ),
      );

      final resultImage = img.decodePng(resultBytes);
      expect(resultImage, isNotNull);
      // Center pixels should be partially or fully preserved
      expect(resultImage!.getPixel(1, 1).a, greaterThan(0));
    });

    test('supports RGB source images without existing alpha channel', () async {
      const processor = PixelCutoutProcessor();

      // Create a 2x2 RGB image (numChannels: 3)
      final rgbImage = img.Image(width: 2, height: 2, numChannels: 3);
      for (int y = 0; y < 2; y++) {
        for (int x = 0; x < 2; x++) {
          rgbImage.setPixelRgb(x, y, 0, 255, 0);
        }
      }
      final rgbBytes = Uint8List.fromList(img.encodePng(rgbImage));

      final mask = <double>[
        0.2, 0.9,
        0.1, 0.95,
      ];

      final resultBytes = await processor.processCutout(
        CutoutProcessingParams(
          imageBytes: rgbBytes,
          maskConfidences: mask,
          maskWidth: 2,
          maskHeight: 2,
          confidenceThreshold: 0.7,
          smoothEdges: false,
        ),
      );

      final resultImage = img.decodePng(resultBytes);
      expect(resultImage, isNotNull);
      expect(resultImage!.hasAlpha, isTrue);
      expect(resultImage.getPixel(0, 0).a, equals(0));
      expect(resultImage.getPixel(1, 0).a, greaterThan(0));
    });

    test('throws ArgumentError on invalid image byte payload', () {
      expect(
        () => PixelCutoutProcessor.execute(
          CutoutProcessingParams(
            imageBytes: Uint8List.fromList([0, 1, 2, 3]),
            maskConfidences: [0.5],
            maskWidth: 1,
            maskHeight: 1,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('uses the image size when no mask size is given', () {
      final image = img.Image(width: 4, height: 2, numChannels: 4)
        ..clear(img.ColorRgba8(10, 20, 30, 255));
      final out = img.decodePng(PixelCutoutProcessor.execute(CutoutProcessingParams(
        imageBytes: Uint8List.fromList(img.encodePng(image)),
        maskConfidences: const [1, 1, 0, 0, 1, 1, 0, 0],
        smoothEdges: false,
      )))!;

      expect(out.getPixel(0, 0).a, 255);
      expect(out.getPixel(3, 1).a, 0);
    });

    test('reports a mask without any foreground', () {
      final image = img.Image(width: 2, height: 2);
      expect(
        () => PixelCutoutProcessor.execute(CutoutProcessingParams(
          imageBytes: Uint8List.fromList(img.encodePng(image)),
          maskConfidences: const [0, 0, 0, 0],
        )),
        throwsA(isA<NoSubjectFoundException>()),
      );
    });

    test('rejects a mask smaller than the image', () {
      final image = img.Image(width: 2, height: 2);
      expect(
        () => PixelCutoutProcessor.execute(CutoutProcessingParams(
          imageBytes: Uint8List.fromList(img.encodePng(image)),
          maskConfidences: const [1, 1],
        )),
        throwsArgumentError,
      );
    });

    test('scales a smaller mask up smoothly', () {
      final image = img.Image(width: 8, height: 1, numChannels: 4)
        ..clear(img.ColorRgba8(10, 20, 30, 255));
      final out = img.decodePng(PixelCutoutProcessor.execute(CutoutProcessingParams(
        imageBytes: Uint8List.fromList(img.encodePng(image)),
        maskConfidences: const [1, 1, 0, 0],
        maskWidth: 4,
        maskHeight: 1,
        confidenceThreshold: 0.5,
        smoothEdges: false,
      )))!;

      expect(out.getPixel(0, 0).a, 255);
      expect(out.getPixel(7, 0).a, 0);
      // Pixel 3 samples 0.75 between the mask's 1 and 0: half visible, a soft
      // edge instead of a hard nearest-neighbour step.
      expect(out.getPixel(3, 0).a, inExclusiveRange(100, 160));
    });
  });
}
