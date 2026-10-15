import 'package:flutter/material.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Scalable vector painter rendering smoothed Bezier curves for a [DoodleLayer].
///
/// Uses midpoint quadratic Bezier interpolation ([Path.quadraticBezierTo]) to produce
/// smooth, anti-aliased freehand strokes and renders optional neon glow filters.
class DoodlePainter extends CustomPainter {
  const DoodlePainter({
    required this.layer,
    required this.canvasSize,
  });

  final DoodleLayer layer;
  final Size canvasSize;

  @override
  void paint(Canvas canvas, Size size) {
    final points = layer.points;
    if (points.isEmpty) return;

    final w = canvasSize.width;
    final h = canvasSize.height;

    // Single point: render as a rounded dot
    if (points.length == 1) {
      final center = Offset(points[0][0] * w, points[0][1] * h);
      final radius = layer.strokeWidth / 2.0;

      if (layer.hasGlow) {
        final glowPaint = Paint()
          ..color = Color(layer.strokeColorValue).withValues(alpha: 0.6)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
        canvas.drawCircle(center, radius + 4.0, glowPaint);
      }

      final dotPaint = Paint()
        ..color = Color(layer.strokeColorValue)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, dotPaint);
      return;
    }

    // Build smoothed quadratic Bezier path
    final path = Path();
    final firstPoint = Offset(points[0][0] * w, points[0][1] * h);
    path.moveTo(firstPoint.dx, firstPoint.dy);

    if (points.length == 2) {
      final secondPoint = Offset(points[1][0] * w, points[1][1] * h);
      path.lineTo(secondPoint.dx, secondPoint.dy);
    } else {
      for (var i = 1; i < points.length - 1; i++) {
        final pCurrent = Offset(points[i][0] * w, points[i][1] * h);
        final pNext = Offset(points[i + 1][0] * w, points[i + 1][1] * h);
        final midPoint = Offset(
          (pCurrent.dx + pNext.dx) / 2.0,
          (pCurrent.dy + pNext.dy) / 2.0,
        );

        path.quadraticBezierTo(pCurrent.dx, pCurrent.dy, midPoint.dx, midPoint.dy);
      }

      final lastPoint = Offset(points.last[0] * w, points.last[1] * h);
      path.lineTo(lastPoint.dx, lastPoint.dy);
    }

    // Render optional neon glow
    if (layer.hasGlow) {
      final glowPaint = Paint()
        ..color = Color(layer.strokeColorValue).withValues(alpha: 0.6)
        ..strokeWidth = layer.strokeWidth + 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
      canvas.drawPath(path, glowPaint);
    }

    // Main stroke
    final strokePaint = Paint()
      ..color = Color(layer.strokeColorValue)
      ..strokeWidth = layer.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant DoodlePainter oldDelegate) {
    return oldDelegate.layer != layer || oldDelegate.canvasSize != canvasSize;
  }
}
