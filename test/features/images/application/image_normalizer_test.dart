import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/features/images/application/image_normalizer.dart';

void main() {
  group('ImageNormalizer.normalize', () {
    test('bakes EXIF orientation into the pixels', () {
      // Stored landscape 40x20 but tagged "rotate 90° CW" (orientation 6),
      // as cameras do for portrait shots.
      final stored = img.Image(width: 40, height: 20)..clear(img.ColorRgb8(0, 0, 255));
      stored.exif.imageIfd.orientation = 6;
      final bytes = Uint8List.fromList(img.encodeJpg(stored));

      final result = ImageNormalizer.normalize(bytes);

      expect(result.width, 20);
      expect(result.height, 40);
      final reDecoded = img.decodeImage(result.bytes)!;
      expect(reDecoded.width, 20);
      expect(reDecoded.height, 40);
    });

    test('downscales the longest edge to maxDimension preserving aspect ratio', () {
      final tall = img.Image(width: 300, height: 600);
      final result = ImageNormalizer.normalize(
        Uint8List.fromList(img.encodePng(tall)),
        maxDimension: 120,
      );

      expect(result.height, 120);
      expect(result.width, 60);
    });

    test('leaves images within the limit at their original size', () {
      final small = img.Image(width: 64, height: 48);
      final result = ImageNormalizer.normalize(Uint8List.fromList(img.encodePng(small)));

      expect(result.width, 64);
      expect(result.height, 48);
    });

    test('stores opaque images as JPEG even if the source had an alpha channel', () {
      final opaqueRgba = img.Image(width: 10, height: 10, numChannels: 4)
        ..clear(img.ColorRgba8(10, 20, 30, 255));
      final result = ImageNormalizer.normalize(Uint8List.fromList(img.encodePng(opaqueRgba)));

      expect(result.extension, 'jpg');
    });

    test('keeps PNG when any pixel is transparent', () {
      final cutout = img.Image(width: 10, height: 10, numChannels: 4)
        ..clear(img.ColorRgba8(10, 20, 30, 255));
      cutout.setPixel(3, 3, img.ColorRgba8(0, 0, 0, 0));
      final result = ImageNormalizer.normalize(Uint8List.fromList(img.encodePng(cutout)));

      expect(result.extension, 'png');
      expect(img.decodePng(result.bytes)!.getPixel(3, 3).a, 0);
    });

    test('rejects bytes that are not an image', () {
      expect(
        () => ImageNormalizer.normalize(Uint8List.fromList(<int>[1, 2, 3])),
        throwsFormatException,
      );
    });
  });
}
