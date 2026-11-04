import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/core/utils/color_filters.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/export/domain/models/models.dart';
import 'package:image_editor/features/fonts/application/font_library_notifier.dart';
import 'package:image_editor/features/fonts/application/font_resolver.dart';
import 'package:image_editor/features/layers/application/doodle_geometry.dart';
import 'package:image_editor/features/layers/application/text_layer_style.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/layers/presentation/widgets/doodle_painter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'canvas_export_service.g.dart';

/// Production export engine that renders the entire canvas workspace
/// headlessly using [ui.PictureRecorder] and [ui.Canvas], decoupled from
/// screen resolution limits.
class CanvasExportService {
  CanvasExportService({
    required this.projectRepository,
    this.installedFontFamilies,
    this.picturesDirectoryProvider,
  });

  final ProjectRepository projectRepository;

  /// Font families that can be rendered (from the font library), so text uses
  /// the same font, or the same fallback, as on the canvas. Returning null
  /// applies every family as-is.
  final Set<String>? Function()? installedFontFamilies;

  /// Optional directory provider override for testing.
  final Future<Directory> Function()? picturesDirectoryProvider;

  /// Renders [project] at the size given by [config]'s resolution tier
  /// (always the canvas aspect ratio), applies the watermark if enabled, and
  /// returns encoded PNG or JPEG bytes.
  Future<Uint8List> renderCanvasToBytes({
    required ProjectModel project,
    required ExportConfig config,
  }) {
    return renderAtSize(
      project: project,
      outputSize: config.outputSize(Size(project.canvasWidth, project.canvasHeight)),
      format: config.format,
      jpegQuality: config.jpegQuality,
      watermark: config.watermark,
    );
  }

  /// Renders [project] into an image of exactly [outputSize] pixels.
  ///
  /// All layers are drawn in *canvas units* (the same coordinate space as the
  /// editor) under a single scale transform, so text, strokes, images and the
  /// watermark keep their proportions at every output resolution.
  Future<Uint8List> renderAtSize({
    required ProjectModel project,
    required Size outputSize,
    ExportFormat format = ExportFormat.png,
    int jpegQuality = 95,
    WatermarkConfig watermark = const WatermarkConfig(),
  }) async {
    final canvasSize = Size(project.canvasWidth, project.canvasHeight);
    final pixelWidth = outputSize.width.round();
    final pixelHeight = outputSize.height.round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pixelWidth.toDouble(), pixelHeight.toDouble()),
    );

    // Map canvas units onto output pixels.
    canvas.scale(
      pixelWidth / canvasSize.width,
      pixelHeight / canvasSize.height,
    );

    // 1. Solid canvas background.
    canvas.drawRect(Offset.zero & canvasSize, Paint()..color = const Color(0xFFFFFFFF));

    // 2. Layers in stacking order.
    final sortedLayers = List<CanvasLayer>.from(project.layers)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    for (final layer in sortedLayers) {
      if (!layer.isVisible) continue;

      canvas.save();
      canvas.translate(layer.x * canvasSize.width, layer.y * canvasSize.height);
      canvas.rotate(layer.rotation);
      canvas.scale(layer.scale);

      if (layer is DoodleLayer) {
        // Same local box as on screen, centered on the layer position.
        final size = DoodleGeometry.localSize(layer, canvasSize);
        canvas.translate(-size.width / 2.0, -size.height / 2.0);
        DoodlePainter(layer: layer, canvasSize: canvasSize).paint(canvas, size);
      } else if (layer is ImageLayer) {
        await _drawImageLayer(canvas, layer);
      } else if (layer is TextLayer) {
        _drawTextLayer(canvas, layer);
      } else if (layer is StickerLayer) {
        await _drawStickerLayer(canvas, layer);
      }

      canvas.restore();
    }

    // 3. Watermark on top, also in canvas units.
    if (watermark.isEnabled) {
      await _drawWatermark(canvas, watermark, canvasSize);
    }

    // 4. Rasterize at the output resolution.
    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(pixelWidth, pixelHeight);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    uiImage.dispose();
    picture.dispose();
    if (byteData == null) {
      throw StateError('Failed to encode headless canvas image to bytes.');
    }

    final pngBytes = byteData.buffer.asUint8List();

    // 5. JPEG encoding is CPU heavy: run it in a background isolate.
    if (format == ExportFormat.jpeg) {
      return Isolate.run(() => _encodeJpegInIsolate(pngBytes, jpegQuality));
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
    final style = FontResolver.apply(
      TextLayerStyle.base(layer),
      layer.fontFamily,
      installedFontFamilies?.call(),
    );

    final painter = TextPainter(
      text: TextSpan(text: layer.text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final boxColor = layer.boxColorValue;
    if (boxColor != null) {
      const padding = TextLayerStyle.boxPadding;
      final boxRect = Rect.fromCenter(
        center: Offset.zero,
        width: painter.width + padding.horizontal,
        height: painter.height + padding.vertical,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, Radius.circular(layer.boxBorderRadius)),
        Paint()..color = Color(boxColor),
      );
    }

    painter.paint(canvas, Offset(-painter.width / 2.0, -painter.height / 2.0));
    painter.dispose();
  }

  Future<void> _drawStickerLayer(Canvas canvas, StickerLayer layer) async {
    try {
      final filePath = layer.relativeFilePath;
      final Uint8List bytes;
      if (filePath != null) {
        bytes = await (await projectRepository.resolveRelativePath(filePath)).readAsBytes();
      } else {
        bytes = (await rootBundle.load(layer.assetPath)).buffer.asUint8List();
      }
      final image = await _decodeImageBytes(bytes);
      if (image == null) return;

      final double w = image.width.toDouble();
      final double h = image.height.toDouble();
      canvas.drawImage(image, Offset(-w / 2.0, -h / 2.0), Paint());
    } catch (_) {
      // Graceful fallback for mock or missing asset during headless export
    }
  }

  /// Margin between a corner watermark and the canvas edge, as a fraction of
  /// the canvas's shorter side.
  static const double watermarkMarginFraction = 0.03;

  /// Width of a logo watermark as a fraction of the canvas width.
  static const double logoWidthFraction = 0.2;

  Future<void> _drawWatermark(
    Canvas canvas,
    WatermarkConfig watermark,
    Size canvasSize,
  ) async {
    final margin = canvasSize.shortestSide * watermarkMarginFraction;

    if (watermark.type == WatermarkType.text) {
      final painter = TextPainter(
        text: TextSpan(
          text: watermark.text,
          style: TextStyle(
            inherit: false,
            color: Color(watermark.colorValue).withValues(alpha: watermark.opacity),
            fontSize: watermark.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      _placeWatermark(
        canvas,
        canvasSize: canvasSize,
        itemSize: painter.size,
        margin: margin,
        position: watermark.position,
        draw: (offset) => painter.paint(canvas, offset),
      );
      painter.dispose();
      return;
    }

    final logoPath = watermark.logoAssetOrFilePath;
    if (logoPath == null) return;

    try {
      final file = File(logoPath);
      final Uint8List logoBytes;
      if (await file.exists()) {
        logoBytes = await file.readAsBytes();
      } else {
        logoBytes = (await rootBundle.load(logoPath)).buffer.asUint8List();
      }

      final logo = await _decodeImageBytes(logoBytes);
      if (logo == null) return;

      final width = canvasSize.width * logoWidthFraction;
      final height = width * logo.height / logo.width;
      final source = Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble());
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: watermark.opacity)
        ..filterQuality = FilterQuality.high;

      _placeWatermark(
        canvas,
        canvasSize: canvasSize,
        itemSize: Size(width, height),
        margin: margin,
        position: watermark.position,
        draw: (offset) => canvas.drawImageRect(
          logo,
          source,
          offset & Size(width, height),
          paint,
        ),
      );
      logo.dispose();
    } catch (_) {
      // A missing or unreadable logo must not fail the whole export.
    }
  }

  /// Draws a watermark item of [itemSize] at [position], or repeats it in a
  /// rotated diagonal pattern for [WatermarkPosition.tiled].
  void _placeWatermark(
    Canvas canvas, {
    required Size canvasSize,
    required Size itemSize,
    required double margin,
    required WatermarkPosition position,
    required void Function(Offset topLeft) draw,
  }) {
    switch (position) {
      case WatermarkPosition.bottomRight:
        draw(Offset(
          canvasSize.width - itemSize.width - margin,
          canvasSize.height - itemSize.height - margin,
        ));
      case WatermarkPosition.bottomLeft:
        draw(Offset(margin, canvasSize.height - itemSize.height - margin));
      case WatermarkPosition.center:
        draw(Offset(
          (canvasSize.width - itemSize.width) / 2.0,
          (canvasSize.height - itemSize.height) / 2.0,
        ));
      case WatermarkPosition.tiled:
        final stepX = itemSize.width * 1.8;
        final stepY = itemSize.height * 4.0;
        if (stepX <= 0 || stepY <= 0) return;
        for (var y = -itemSize.height; y < canvasSize.height + stepY; y += stepY) {
          for (var x = -itemSize.width; x < canvasSize.width + stepX; x += stepX) {
            canvas.save();
            canvas.translate(x, y);
            canvas.rotate(-0.35); // about -20 degrees
            draw(Offset.zero);
            canvas.restore();
          }
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

/// App-wide singleton [CanvasExportService].
@Riverpod(keepAlive: true)
CanvasExportService canvasExportService(Ref ref) {
  return CanvasExportService(
    projectRepository: ref.watch(projectRepositoryProvider),
    installedFontFamilies: () => ref.read(fontLibraryProvider).value?.installedFamilies,
  );
}
