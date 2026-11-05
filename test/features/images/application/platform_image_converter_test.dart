import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/features/images/application/image_normalizer.dart';
import 'package:image_editor/features/images/application/platform_image_converter.dart';

/// The first bytes of a HEIC file from a phone camera (ISO-BMFF `ftyp` box).
Uint8List heicHeader([String brand = 'heic']) => Uint8List.fromList([
      0, 0, 0, 24, ...'ftyp'.codeUnits, ...brand.codeUnits, 0, 0, 0, 0, //
      ...'mif1'.codeUnits, ...'heic'.codeUnits, 1, 2, 3, 4,
    ]);

/// Pretends to be Android's decoder: a solid red image of the asked size.
class FakePlatformDecoder {
  int calls = 0;
  int? requestedMax;

  Future<DecodedPixels> call(Uint8List bytes, int maxDimension) async {
    calls++;
    requestedMax = maxDimension;
    const width = 40, height = 20;
    final rgba = Uint8List(width * height * 4);
    for (var i = 0; i < rgba.length; i += 4) {
      rgba[i] = 255;
      rgba[i + 3] = 255;
    }
    return DecodedPixels(rgba: rgba, width: width, height: height);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final jpeg = Uint8List.fromList(img.encodeJpg(img.Image(width: 8, height: 4)));

  test('recognizes HEIC, HEIF and AVIF files, but not JPEG', () {
    expect(PlatformImageConverter.isHeifFamily(heicHeader()), isTrue);
    expect(PlatformImageConverter.isHeifFamily(heicHeader('mif1')), isTrue);
    expect(PlatformImageConverter.isHeifFamily(heicHeader('avif')), isTrue);
    expect(PlatformImageConverter.isHeifFamily(heicHeader('isom')), isFalse, reason: 'MP4 video');
    expect(PlatformImageConverter.isHeifFamily(jpeg), isFalse);
    expect(PlatformImageConverter.isHeifFamily(Uint8List(3)), isFalse);
  });

  test('JPEG and PNG pass through without platform decoding', () async {
    final decoder = FakePlatformDecoder();

    expect(await PlatformImageConverter.ensureDecodable(jpeg, decode: decoder.call), same(jpeg));
    expect(decoder.calls, 0);
  });

  test('HEIC is converted to a JPEG the image package can read', () async {
    final decoder = FakePlatformDecoder();

    final converted = await PlatformImageConverter.ensureDecodable(
      heicHeader(),
      maxDimension: 1024,
      decode: decoder.call,
    );

    expect(decoder.requestedMax, 1024);
    final image = img.decodeJpg(converted)!;
    expect(image.width, 40);
    expect(image.height, 20);
    expect(image.getPixel(5, 5).r, greaterThan(240));
  });

  test('a file nothing can decode is reported as unsupported', () async {
    Future<DecodedPixels> failing(Uint8List bytes, int max) async =>
        throw const FormatException('The selected file is not a supported image.');

    await expectLater(
      PlatformImageConverter.ensureDecodable(Uint8List.fromList([1, 2, 3, 4, 5]), decode: failing),
      throwsFormatException,
    );
  });

  test('imports of HEIC photos are normalized like any other photo', () async {
    final decoder = FakePlatformDecoder();

    final normalized = await ImageNormalizer.normalizeInBackground(
      heicHeader(),
      platformDecode: decoder.call,
    );

    expect(decoder.calls, 1);
    expect(normalized.extension, 'jpg');
    expect(normalized.width, 40);
    expect(normalized.height, 20);
  });

  testWidgets('the engine decoder downscales to the requested size', (tester) async {
    final png = Uint8List.fromList(img.encodePng(img.Image(width: 400, height: 200)));

    final pixels = await tester.runAsync(() => PlatformImageConverter.decodeWithPlatform(png, 100));

    expect(pixels!.width, 100);
    expect(pixels.height, 50);
    expect(pixels.rgba.length, 100 * 50 * 4);
  });

  testWidgets('the engine decoder rejects garbage with a FormatException', (tester) async {
    Object? error;
    await tester.runAsync(() async {
      try {
        await PlatformImageConverter.decodeWithPlatform(heicHeader(), 100);
      } catch (e) {
        error = e;
      }
    });
    expect(error, isA<FormatException>());
  });
}
