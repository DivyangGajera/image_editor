import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_editor/features/images/application/platform_image_converter.dart';

/// Result of [ImageNormalizer.normalize]: re-encoded bytes plus their pixel size.
class NormalizedImage {
  const NormalizedImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.extension,
  });

  /// Encoded image bytes (PNG when the source has transparency, JPEG otherwise).
  final Uint8List bytes;
  final int width;
  final int height;

  /// File extension matching [bytes], without the dot (`png` or `jpg`).
  final String extension;
}

/// Prepares imported photos for the canvas.
///
/// * Applies the EXIF orientation to the pixels, so camera photos are upright
///   everywhere (rendering, ML segmentation, export) without relying on metadata.
/// * Downscales so the longest edge is at most [maxDimension] pixels, which
///   bounds memory use while staying sharp for 4K exports.
/// * Keeps transparency as PNG; opaque photos are stored as JPEG to save space.
abstract final class ImageNormalizer {
  /// Longest edge, in pixels, of an imported image.
  static const int maxDimension = 2048;

  /// JPEG quality used for opaque imports.
  static const int jpegQuality = 92;

  /// Runs [normalize] in a background isolate. Formats the `image` package
  /// cannot read, such as HEIC camera photos, are converted by the platform
  /// first (see [PlatformImageConverter]).
  static Future<NormalizedImage> normalizeInBackground(
    Uint8List bytes, {
    int maxDimension = ImageNormalizer.maxDimension,
    PlatformImageDecode platformDecode = PlatformImageConverter.decodeWithPlatform,
  }) async {
    final decodable = await PlatformImageConverter.ensureDecodable(
      bytes,
      maxDimension: maxDimension,
      decode: platformDecode,
    );
    return Isolate.run(() => normalize(decodable, maxDimension: maxDimension));
  }

  /// Decodes, orients, downscales and re-encodes [bytes]. Pure and synchronous;
  /// call [normalizeInBackground] from the UI isolate.
  static NormalizedImage normalize(
    Uint8List bytes, {
    int maxDimension = ImageNormalizer.maxDimension,
  }) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } on Object {
      // Decoders throw arbitrary errors (e.g. RangeError) on corrupt input.
      decoded = null;
    }
    if (decoded == null) {
      throw const FormatException('The selected file is not a supported image.');
    }

    var image = img.bakeOrientation(decoded);

    final longestEdge = math.max(image.width, image.height);
    if (longestEdge > maxDimension) {
      final ratio = maxDimension / longestEdge;
      image = img.copyResize(
        image,
        width: math.max(1, (image.width * ratio).round()),
        height: math.max(1, (image.height * ratio).round()),
        interpolation: img.Interpolation.average,
      );
    }

    final keepAlpha = image.hasAlpha && _hasTransparentPixel(image);
    final encoded = keepAlpha
        ? img.encodePng(image)
        : img.encodeJpg(image, quality: jpegQuality);

    return NormalizedImage(
      bytes: Uint8List.fromList(encoded),
      width: image.width,
      height: image.height,
      extension: keepAlpha ? 'png' : 'jpg',
    );
  }

  static bool _hasTransparentPixel(img.Image image) {
    for (final pixel in image) {
      if (pixel.a < pixel.maxChannelValue) return true;
    }
    return false;
  }
}
