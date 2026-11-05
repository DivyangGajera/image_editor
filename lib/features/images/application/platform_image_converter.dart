import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

/// Raw RGBA pixels decoded by the platform.
class DecodedPixels {
  const DecodedPixels({required this.rgba, required this.width, required this.height});
  final Uint8List rgba;
  final int width;
  final int height;
}

/// Decodes [bytes] to at most [maxDimension] px on the longest edge.
typedef PlatformImageDecode = Future<DecodedPixels> Function(Uint8List bytes, int maxDimension);

/// Converts images the pure-Dart `image` package cannot read, such as HEIC /
/// HEIF photos from modern phone cameras (and AVIF), into JPEG.
///
/// Decoding goes through Flutter's engine, which hands formats it does not
/// know itself to Android's ImageDecoder (HEIF on Android 9+). That decoder
/// also applies the EXIF orientation. Only the JPEG encoding runs in an
/// isolate; the engine decodes off the UI thread on its own.
abstract final class PlatformImageConverter {
  /// JPEG quality of converted images; they are re-encoded once more later.
  static const int jpegQuality = 95;

  static const Set<String> _isoBmffImageBrands = {
    'heic', 'heix', 'hevc', 'hevx', 'heim', 'heis', 'hevm', 'hevs', 'mif1', 'msf1', 'avif', 'avis',
  };

  /// Whether [bytes] are a HEIF-family (HEIC, HEIF, AVIF) image.
  static bool isHeifFamily(Uint8List bytes) {
    if (bytes.length < 12) return false;
    if (String.fromCharCodes(bytes.sublist(4, 8)) != 'ftyp') return false;
    return _isoBmffImageBrands.contains(String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase());
  }

  /// Returns [bytes] unchanged when the `image` package can read them, or
  /// a JPEG conversion (at most [maxDimension] px) otherwise.
  ///
  /// Throws a [FormatException] when no decoder can read the file.
  static Future<Uint8List> ensureDecodable(
    Uint8List bytes, {
    int maxDimension = 2048,
    PlatformImageDecode decode = decodeWithPlatform,
  }) async {
    if (!isHeifFamily(bytes) && _dartCanDecode(bytes)) return bytes;
    final pixels = await decode(bytes, maxDimension);
    return Isolate.run(() => encodeJpeg(pixels));
  }

  static bool _dartCanDecode(Uint8List bytes) {
    try {
      return img.findDecoderForData(bytes) != null;
    } on Object {
      // The format sniffers throw on very short or corrupt data.
      return false;
    }
  }

  /// Encodes decoded pixels as JPEG. Pure; run it in an isolate.
  static Uint8List encodeJpeg(DecodedPixels pixels) {
    final image = img.Image.fromBytes(
      width: pixels.width,
      height: pixels.height,
      bytes: pixels.rgba.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return Uint8List.fromList(img.encodeJpg(image, quality: jpegQuality));
  }

  /// Decodes with Flutter's engine (and through it, Android's decoders).
  static Future<DecodedPixels> decodeWithPlatform(Uint8List bytes, int maxDimension) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      codec = await ui.instantiateImageCodecWithSize(
        buffer,
        getTargetSize: (width, height) {
          final longest = math.max(width, height);
          if (longest <= maxDimension) return ui.TargetImageSize(width: width, height: height);
          final ratio = maxDimension / longest;
          return ui.TargetImageSize(
            width: math.max(1, (width * ratio).round()),
            height: math.max(1, (height * ratio).round()),
          );
        },
      );
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) throw const FormatException('No pixels');
      return DecodedPixels(
        rgba: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        width: image.width,
        height: image.height,
      );
    } on Object {
      throw const FormatException('The selected file is not a supported image.');
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
}
