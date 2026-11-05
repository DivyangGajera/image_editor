import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_editor/features/export/domain/models/watermark_config.dart';

/// Draws a [WatermarkConfig] in canvas units. Shared by the export (at full
/// resolution) and the export screen's live preview, so what the user sees
/// is exactly what is saved.
abstract final class WatermarkRenderer {
  /// Margin between a corner watermark and the canvas edge, as a fraction of
  /// the canvas's shorter side.
  static const double marginFraction = 0.03;

  /// Paints [watermark] on [canvas], whose coordinate space is the project's
  /// canvas of [canvasSize]. Logo watermarks need the decoded [logo]; without
  /// it nothing is drawn.
  static void paint(Canvas canvas, Size canvasSize, WatermarkConfig watermark, {ui.Image? logo}) {
    final margin = canvasSize.shortestSide * marginFraction;

    if (watermark.type == WatermarkType.text) {
      if (watermark.text.trim().isEmpty) return;
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

      _place(
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

    if (logo == null) return;
    final size = logoSize(canvasSize, watermark, logo);
    final source = Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble());
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: watermark.opacity)
      ..filterQuality = FilterQuality.high;
    _place(
      canvas,
      canvasSize: canvasSize,
      itemSize: size,
      margin: margin,
      position: watermark.position,
      draw: (offset) => canvas.drawImageRect(logo, source, offset & size, paint),
    );
  }

  /// Size of the logo on a canvas of [canvasSize], in canvas units.
  static Size logoSize(Size canvasSize, WatermarkConfig watermark, ui.Image logo) {
    final width = canvasSize.width * watermark.logoScale;
    return Size(width, width * logo.height / logo.width);
  }

  /// Draws an item of [itemSize] at [position], or repeats it in a rotated
  /// diagonal pattern for [WatermarkPosition.tiled].
  static void _place(
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
}
