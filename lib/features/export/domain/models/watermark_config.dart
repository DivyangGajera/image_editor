import 'package:flutter/foundation.dart';
import 'package:image_editor/core/constants/app_constants.dart';

/// Positioning strategy for applying watermarks on the exported canvas.
enum WatermarkPosition {
  /// Pinned to bottom-right corner with margin.
  bottomRight,

  /// Pinned to bottom-left corner with margin.
  bottomLeft,

  /// Positioned directly in the center of the canvas.
  center,

  /// Repeated diagonally in a tiled grid pattern across the entire canvas.
  tiled,
}

/// Type of watermark to render (text string or image logo).
enum WatermarkType {
  /// Custom text string rendered with styled typography.
  text,

  /// Transparent PNG image logo.
  logo,
}

/// Configuration settings for adding watermarks during canvas export.
@immutable
class WatermarkConfig {
  const WatermarkConfig({
    this.isEnabled = false,
    this.type = WatermarkType.text,
    this.text = AppConstants.appShortName,
    this.logoAssetOrFilePath,
    this.position = WatermarkPosition.bottomRight,
    this.opacity = 0.75,
    this.fontSize = 24.0,
    this.colorValue = 0xFFFFFFFF,
  });

  /// Whether watermarking is active.
  final bool isEnabled;

  /// Whether to render text or an image logo.
  final WatermarkType type;

  /// Custom watermark text string.
  final String text;

  /// File path or asset path for a transparent PNG logo.
  final String? logoAssetOrFilePath;

  /// Layout placement strategy.
  final WatermarkPosition position;

  /// Opacity multiplier between 0.1 and 1.0.
  final double opacity;

  /// Font size for text watermarks (in canvas pixels).
  final double fontSize;

  /// ARGB integer color of text watermark.
  final int colorValue;

  WatermarkConfig copyWith({
    bool? isEnabled,
    WatermarkType? type,
    String? text,
    String? logoAssetOrFilePath,
    WatermarkPosition? position,
    double? opacity,
    double? fontSize,
    int? colorValue,
    bool clearLogo = false,
  }) {
    return WatermarkConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      type: type ?? this.type,
      text: text ?? this.text,
      logoAssetOrFilePath:
          clearLogo ? null : (logoAssetOrFilePath ?? this.logoAssetOrFilePath),
      position: position ?? this.position,
      opacity: opacity ?? this.opacity,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatermarkConfig &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          type == other.type &&
          text == other.text &&
          logoAssetOrFilePath == other.logoAssetOrFilePath &&
          position == other.position &&
          opacity == other.opacity &&
          fontSize == other.fontSize &&
          colorValue == other.colorValue;

  @override
  int get hashCode => Object.hash(
        isEnabled,
        type,
        text,
        logoAssetOrFilePath,
        position,
        opacity,
        fontSize,
        colorValue,
      );
}
