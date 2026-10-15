import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/core/utils/color_filters.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/export/domain/models/models.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/layers/presentation/widgets/doodle_painter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Production export engine that renders the entire canvas workspace
/// headlessly using [ui.PictureRecorder] and [ui.Canvas], decoupled from
/// screen resolution limits.
class CanvasExportService {
  const CanvasExportService({
    required this.projectRepository,
    this.picturesDirectoryProvider,
  });

  final ProjectRepository projectRepository;

  /// Optional directory provider override for testing.
  final Future<Directory> Function()? picturesDirectoryProvider;

  /// Renders all layers in [project] at the resolution specified by [config],
  /// applies watermarks if enabled, and returns raw encoded PNG or JPEG bytes.
  Future<Uint8List> renderCanvasToBytes({
    required ProjectModel project,
    required ExportConfig config,
  }) async {
    final double targetWidth = config.width;
    final double targetHeight = config.height;
    final targetSize = Size(targetWidth, targetHeight);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, targetWidth, targetHeight),
    );

    // 1. Draw solid background
    final bgPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(0, 0, targetWidth, targetHeight), bgPaint);

    // 2. Sort layers according to z-index
    final sortedLayers = List<CanvasLayer>.from(project.layers)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    // 3. Render each visible layer
    for (final layer in sortedLayers) {
      if (!layer.isVisible) continue;

      if (layer is DoodleLayer) {
        // Doodle layers use canvas-wide normalized points
        final painter = DoodlePainter(layer: layer, canvasSize: targetSize);
        painter.paint(canvas, targetSize);
        continue;
      }

      canvas.save();

      // Transform coordinate space to layer center
      final double pixelX = layer.x * targetWidth;
      final double pixelY = layer.y * targetHeight;
      canvas.translate(pixelX, pixelY);
      canvas.rotate(layer.rotation);
      canvas.scale(layer.scale);

      if (layer is ImageLayer) {
        await _drawImageLayer(canvas, layer);
      } else if (layer is TextLayer) {
        _drawTextLayer(canvas, layer);
      } else if (layer is StickerLayer) {
        await _drawStickerLayer(canvas, layer);
      }

      canvas.restore();
    }

    // 4. Render watermark layer if enabled
    if (config.watermark.isEnabled) {
      await _drawWatermark(canvas, config.watermark, targetWidth, targetHeight);
    }

    // 5. Finalize picture and convert to ui.Image
    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(
      targetWidth.round(),
      targetHeight.round(),
    );

    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode headless canvas image to bytes.');
    }

    final pngBytes = byteData.buffer.asUint8List();

    // 6. Encode to JPEG in background isolate if requested
    if (config.format == ExportFormat.jpeg) {
      return Isolate.run(
        () => _encodeJpegInIsolate(pngBytes, config.jpegQuality),
      );
    }

    return pngBytes;
  }

  /// Saves exported image bytes into the system pictures or documents directory.
  Future<String> saveExportToGallery({
    required Uint8List bytes,
    required String filename,
  }) async {
    final Directory baseDir;
    if (picturesDirectoryProvider != null) {
      baseDir = await picturesDirectoryProvider!();
    } else {
      Directory? picturesDir;
      try {
        if (!kIsWeb && Platform.isAndroid) {
          final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.pictures,
          );
          if (dirs != null && dirs.isNotEmpty) {
            picturesDir = dirs.first;
          }
        }
      } catch (_) {
        picturesDir = null;
      }
      baseDir = picturesDir ?? await getApplicationDocumentsDirectory();
    }

    final exportDir = Directory(p.join(baseDir.path, 'Exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final targetFile = File(p.join(exportDir.path, filename));
    await targetFile.writeAsBytes(bytes, flush: true);
    return targetFile.path;
  }

  Future<void> _drawImageLayer(Canvas canvas, ImageLayer layer) async {
    try {
      final file = await projectRepository.resolveRelativePath(layer.relativeImagePath);
      if (!await file.exists()) return;

      final bytes = await file.readAsBytes();
      final image = await _decodeImageBytes(bytes);
      if (image == null) return;

      final paint = Paint();
      if (layer.activeFilter != null) {
        paint.colorFilter = AppColorFilters.getFilterByName(layer.activeFilter);
      }

      if (layer.isFlippedHorizontally) {
        canvas.scale(-1.0, 1.0);
      }

      final double w = image.width.toDouble();
      final double h = image.height.toDouble();
      canvas.drawImage(image, Offset(-w / 2.0, -h / 2.0), paint);
    } catch (_) {
      // Graceful degradation on missing or corrupt image
    }
  }

  void _drawTextLayer(Canvas canvas, TextLayer layer) {
    final textStyle = TextStyle(
      color: Color(layer.textColorValue),
      fontSize: layer.fontSize,
      fontWeight: layer.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: layer.isItalic ? FontStyle.italic : FontStyle.normal,
      fontFamily: layer.fontFamily,
      shadows: layer.shadowColorValue != null
          ? [
              Shadow(
                color: Color(layer.shadowColorValue!),
                blurRadius: 4.0,
                offset: const Offset(2.0, 2.0),
              ),
            ]
          : null,
    );

    final span = TextSpan(text: layer.text, style: textStyle);
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    painter.layout();

    // Draw background bounding box if configured
    if (layer.boxColorValue != null) {
      const paddingH = 12.0;
      const paddingV = 6.0;
      final boxRect = Rect.fromCenter(
        center: Offset.zero,
        width: painter.width + (paddingH * 2.0),
        height: painter.height + (paddingV * 2.0),
      );
      final rrect = RRect.fromRectAndRadius(
        boxRect,
        Radius.circular(layer.boxBorderRadius),
      );
      canvas.drawRRect(rrect, Paint()..color = Color(layer.boxColorValue!));
    }

    // Paint text centered
    painter.paint(canvas, Offset(-painter.width / 2.0, -painter.height / 2.0));
  }

  Future<void> _drawStickerLayer(Canvas canvas, StickerLayer layer) async {
    try {
      final byteData = await rootBundle.load(layer.assetPath);
      final bytes = byteData.buffer.asUint8List();
      final image = await _decodeImageBytes(bytes);
      if (image == null) return;

      final double w = image.width.toDouble();
      final double h = image.height.toDouble();
      canvas.drawImage(image, Offset(-w / 2.0, -h / 2.0), Paint());
    } catch (_) {
      // Graceful fallback for mock or missing asset during headless export
    }
  }

  Future<void> _drawWatermark(
    Canvas canvas,
    WatermarkConfig watermark,
    double canvasWidth,
    double canvasHeight,
  ) async {
    if (watermark.type == WatermarkType.text) {
      final style = TextStyle(
        color: Color(watermark.colorValue).withValues(alpha: watermark.opacity),
        fontSize: watermark.fontSize,
        fontWeight: FontWeight.bold,
      );

      final span = TextSpan(text: watermark.text, style: style);
      final painter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      painter.layout();

      const double margin = 32.0;

      switch (watermark.position) {
        case WatermarkPosition.bottomRight:
          final offset = Offset(
            canvasWidth - painter.width - margin,
            canvasHeight - painter.height - margin,
          );
          painter.paint(canvas, offset);
          break;
        case WatermarkPosition.bottomLeft:
          final offset = Offset(
            margin,
            canvasHeight - painter.height - margin,
          );
          painter.paint(canvas, offset);
          break;
        case WatermarkPosition.center:
          final offset = Offset(
            (canvasWidth - painter.width) / 2.0,
            (canvasHeight - painter.height) / 2.0,
          );
          painter.paint(canvas, offset);
          break;
        case WatermarkPosition.tiled:
          final stepX = (painter.width * 1.8).clamp(100.0, 500.0);
          final stepY = (painter.height * 4.0).clamp(60.0, 300.0);

          for (double y = 0; y < canvasHeight + 100; y += stepY) {
            for (double x = 0; x < canvasWidth + 100; x += stepX) {
              canvas.save();
              canvas.translate(x, y);
              canvas.rotate(-0.35); // ~ -20 degrees
              painter.paint(canvas, Offset.zero);
              canvas.restore();
            }
          }
          break;
      }
    } else if (watermark.type == WatermarkType.logo &&
        watermark.logoAssetOrFilePath != null) {
      try {
        final file = File(watermark.logoAssetOrFilePath!);
        final Uint8List logoBytes;
        if (await file.exists()) {
          logoBytes = await file.readAsBytes();
        } else {
          final data = await rootBundle.load(watermark.logoAssetOrFilePath!);
          logoBytes = data.buffer.asUint8List();
        }

        final logo = await _decodeImageBytes(logoBytes);
        if (logo == null) return;

        final paint = Paint()
          ..color = Colors.white.withValues(alpha: watermark.opacity);
        final w = logo.width.toDouble();
        final h = logo.height.toDouble();

        const double margin = 32.0;

        switch (watermark.position) {
          case WatermarkPosition.bottomRight:
            canvas.drawImage(
              logo,
              Offset(canvasWidth - w - margin, canvasHeight - h - margin),
              paint,
            );
            break;
          case WatermarkPosition.bottomLeft:
            canvas.drawImage(
              logo,
              Offset(margin, canvasHeight - h - margin),
              paint,
            );
            break;
          case WatermarkPosition.center:
            canvas.drawImage(
              logo,
              Offset((canvasWidth - w) / 2.0, (canvasHeight - h) / 2.0),
              paint,
            );
            break;
          case WatermarkPosition.tiled:
            for (double y = 0; y < canvasHeight; y += h * 2.0) {
              for (double x = 0; x < canvasWidth; x += w * 2.0) {
                canvas.drawImage(logo, Offset(x, y), paint);
              }
            }
            break;
        }
      } catch (_) {
        // Fallback gracefully
      }
    }
  }

  static Future<ui.Image?> _decodeImageBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static Uint8List _encodeJpegInIsolate(Uint8List pngBytes, int quality) {
    final image = img.decodeImage(pngBytes);
    if (image == null) {
      throw ArgumentError('Failed to decode intermediate PNG for JPEG conversion.');
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }
}

/// Riverpod provider for [CanvasExportService].
final canvasExportServiceProvider = Provider<CanvasExportService>((ref) {
  final projectRepo = ref.watch(projectRepositoryProvider);
  return CanvasExportService(projectRepository: projectRepo);
});
