import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Input parameters passed into background isolate for pixel extraction.
class CutoutProcessingParams {
  const CutoutProcessingParams({
    required this.imageBytes,
    required this.maskConfidences,
    this.maskWidth,
    this.maskHeight,
    this.confidenceThreshold = 0.7,
    this.smoothEdges = true,
  });

  /// Raw bytes of source image to decode and segment.
  final Uint8List imageBytes;

  /// Flattened, row-major foreground confidences (0.0 to 1.0).
  final List<double> maskConfidences;

  /// Width of the mask, or null when it matches the image (ML Kit Subject
  /// Segmentation returns a mask the size of the input image).
  final int? maskWidth;

  /// Height of the mask, or null when it matches the image.
  final int? maskHeight;

  /// Minimum confidence threshold to consider a pixel foreground (defaults to 0.7).
  final double confidenceThreshold;

  /// Whether to apply alpha edge smoothing to eliminate fringe artifacts.
  final bool smoothEdges;
}

/// Thrown when the mask contains no foreground at all.
class NoSubjectFoundException implements Exception {
  const NoSubjectFoundException();

  @override
  String toString() => 'NoSubjectFoundException: no foreground subject in the image';
}

/// Concurrency worker performing raw pixel alpha-blending and contour feathering
/// in a dedicated Dart [Isolate].
class PixelCutoutProcessor {
  const PixelCutoutProcessor();

  /// Runs the cutout algorithm in a background isolate via [Isolate.run].
  Future<Uint8List> processCutout(CutoutProcessingParams params) {
    return Isolate.run(() => execute(params));
  }

  /// Top-level or static processing logic executing within the background isolate.
  static Uint8List execute(CutoutProcessingParams params) {
    final decoded = img.decodeImage(params.imageBytes);
    if (decoded == null) {
      throw ArgumentError('Failed to decode image bytes into valid bitmap.');
    }

    // Ensure 4 channels (RGBA) so alpha transparency is supported
    var image = decoded.hasAlpha ? decoded : decoded.convert(numChannels: 4);

    final imgWidth = image.width;
    final imgHeight = image.height;
    final maskW = params.maskWidth ?? imgWidth;
    final maskH = params.maskHeight ?? imgHeight;
    final confidences = params.maskConfidences;
    if (confidences.length < maskW * maskH) {
      throw ArgumentError(
        'Mask has ${confidences.length} values, expected ${maskW * maskH} (${maskW}x$maskH).',
      );
    }
    final threshold = params.confidenceThreshold;

    // Buffer to hold intermediate alpha values for edge smoothing
    final alphas = Uint8List(imgWidth * imgHeight);

    // 1. Compute alpha channel based on confidence mask
    for (int y = 0; y < imgHeight; y++) {
      final my = (y * maskH ~/ imgHeight).clamp(0, maskH - 1);
      final maskRowOffset = my * maskW;
      final imgRowOffset = y * imgWidth;

      for (int x = 0; x < imgWidth; x++) {
        final mx = (x * maskW ~/ imgWidth).clamp(0, maskW - 1);
        final confidence = confidences[maskRowOffset + mx];

        if (confidence < threshold) {
          alphas[imgRowOffset + x] = 0;
        } else {
          // Soft ramp between threshold and 1.0 for anti-aliased edges
          final range = 1.0 - threshold;
          final factor = range > 0.0 ? ((confidence - threshold) / range).clamp(0.0, 1.0) : 1.0;
          final pixelAlpha = image.getPixel(x, y).a;
          alphas[imgRowOffset + x] = (pixelAlpha * factor).round().clamp(0, 255);
        }
      }
    }

    if (!alphas.any((alpha) => alpha > 0)) {
      throw const NoSubjectFoundException();
    }

    // 2. Edge smoothing: 3x3 box blur on alpha channel along transition boundaries
    final finalAlphas = Uint8List.fromList(alphas);
    if (params.smoothEdges) {
      for (int y = 1; y < imgHeight - 1; y++) {
        final rowOffset = y * imgWidth;
        for (int x = 1; x < imgWidth - 1; x++) {
          final currentAlpha = alphas[rowOffset + x];

          // Only feather pixels on the boundary (semi-transparent or near 0-alpha neighbors)
          if (currentAlpha > 0 && currentAlpha < 255) {
            int sum = 0;
            sum += alphas[(y - 1) * imgWidth + (x - 1)];
            sum += alphas[(y - 1) * imgWidth + x];
            sum += alphas[(y - 1) * imgWidth + (x + 1)];
            sum += alphas[rowOffset + (x - 1)];
            sum += currentAlpha;
            sum += alphas[rowOffset + (x + 1)];
            sum += alphas[(y + 1) * imgWidth + (x - 1)];
            sum += alphas[(y + 1) * imgWidth + x];
            sum += alphas[(y + 1) * imgWidth + (x + 1)];

            finalAlphas[rowOffset + x] = (sum ~/ 9).clamp(0, 255);
          }
        }
      }
    }

    // 3. Write modified alpha values back to image pixels
    for (int y = 0; y < imgHeight; y++) {
      final rowOffset = y * imgWidth;
      for (int x = 0; x < imgWidth; x++) {
        final pixel = image.getPixel(x, y);
        pixel.a = finalAlphas[rowOffset + x];
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }
}
