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

/// Parameters configuring image format, resolution, compression, and watermarks for export.
@immutable
class ExportConfig {
  const ExportConfig({
    this.format = ExportFormat.png,
    this.width = AppConstants.defaultCanvasWidth,
    this.height = AppConstants.defaultCanvasWidth,
    this.jpegQuality = AppConstants.defaultExportQuality,
    this.watermark = const WatermarkConfig(),
  });

  /// Output image format (PNG or JPEG).
  final ExportFormat format;

  /// Target export pixel width.
  final double width;

  /// Target export pixel height.
  final double height;

  /// JPEG compression quality (1 to 100, defaults to 95).
  final int jpegQuality;

  /// Watermark settings.
  final WatermarkConfig watermark;

  ExportConfig copyWith({
    ExportFormat? format,
    double? width,
    double? height,
    int? jpegQuality,
    WatermarkConfig? watermark,
  }) {
    return ExportConfig(
      format: format ?? this.format,
      width: width ?? this.width,
      height: height ?? this.height,
      jpegQuality: jpegQuality ?? this.jpegQuality,
      watermark: watermark ?? this.watermark,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportConfig &&
          runtimeType == other.runtimeType &&
          format == other.format &&
          width == other.width &&
          height == other.height &&
          jpegQuality == other.jpegQuality &&
          watermark == other.watermark;

  @override
  int get hashCode => Object.hash(format, width, height, jpegQuality, watermark);
}
