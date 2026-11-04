import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/features/export/domain/models/watermark_config.dart';

/// Supported image export formats.
enum ExportFormat {
  /// Lossless Portable Network Graphics with alpha transparency support.
  png,

  /// Joint Photographic Experts Group with configurable compression quality.
  jpeg,
}

/// Export quality tiers. The output always keeps the canvas aspect ratio, so an
/// export matches what the user saw on the canvas.
enum ExportResolution {
  /// The canvas's own size (e.g. 1080 x 1350 for a 4:5 post).
  standard(null, 'Standard'),

  /// Longest edge 2560 px.
  twoK(2560, '2K'),

  /// Longest edge 3840 px.
  fourK(3840, '4K');

  const ExportResolution(this.longEdge, this.label);

  /// Target longest edge in pixels, or null for the canvas's own size.
  final int? longEdge;

  /// Short user-facing name.
  final String label;

  /// Output pixel size for a canvas of [canvasSize], preserving its aspect ratio.
  Size outputSizeFor(Size canvasSize) {
    final edge = longEdge;
    if (edge == null || canvasSize.isEmpty) {
      return Size(
        canvasSize.width.roundToDouble(),
        canvasSize.height.roundToDouble(),
      );
    }
    final factor = edge / math.max(canvasSize.width, canvasSize.height);
    return Size(
      math.max(1.0, (canvasSize.width * factor).roundToDouble()),
      math.max(1.0, (canvasSize.height * factor).roundToDouble()),
    );
  }
}

/// Parameters configuring image format, resolution, compression, and watermarks for export.
@immutable
class ExportConfig {
  const ExportConfig({
    this.format = ExportFormat.png,
    this.resolution = ExportResolution.standard,
    this.jpegQuality = AppConstants.defaultExportQuality,
    this.watermark = const WatermarkConfig(),
  });

  /// Output image format (PNG or JPEG).
  final ExportFormat format;

  /// Quality tier determining the output pixel size.
  final ExportResolution resolution;

  /// JPEG compression quality (1-100). Ignored for PNG.
  final int jpegQuality;

  /// Watermark applied on top of the rendered canvas.
  final WatermarkConfig watermark;

  /// Output pixel size for a canvas of [canvasSize].
  Size outputSize(Size canvasSize) => resolution.outputSizeFor(canvasSize);

  ExportConfig copyWith({
    ExportFormat? format,
    ExportResolution? resolution,
    int? jpegQuality,
    WatermarkConfig? watermark,
  }) {
    return ExportConfig(
      format: format ?? this.format,
      resolution: resolution ?? this.resolution,
      jpegQuality: jpegQuality ?? this.jpegQuality,
      watermark: watermark ?? this.watermark,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportConfig &&
          format == other.format &&
          resolution == other.resolution &&
          jpegQuality == other.jpegQuality &&
          watermark == other.watermark;

  @override
  int get hashCode => Object.hash(format, resolution, jpegQuality, watermark);
}
