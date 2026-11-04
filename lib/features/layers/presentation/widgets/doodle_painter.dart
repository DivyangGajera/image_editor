import 'package:flutter/material.dart';
import 'package:image_editor/features/layers/application/doodle_geometry.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Scalable vector painter rendering smoothed Bezier curves for a [DoodleLayer].
///
/// Uses midpoint quadratic Bezier interpolation ([Path.quadraticBezierTo]) to produce
/// smooth, anti-aliased freehand strokes and renders optional neon glow filters.
///
/// By default it paints into the doodle's local box (see [DoodleGeometry]),
/// offsetting points by the stroke padding. Set [inLocalBox] to false to paint
/// raw canvas-normalized points over the whole canvas (live drawing preview).
class DoodlePainter extends CustomPainter {
  const DoodlePainter({
    required this.layer,
    required this.canvasSize,
    this.inLocalBox = true,
  });

  final DoodleLayer layer;
  final Size canvasSize;
  final bool inLocalBox;

  @override
  void paint(Canvas canvas, Size size) {
    final points = layer.points;
    if (points.isEmpty) return;

    final w = canvasSize.width;
    final h = canvasSize.height;
    final pad = inLocalBox ? DoodleGeometry.padding(layer) : 0.0;
    Offset at(List<double> point) => Offset(point[0] * w + pad, point[1] * h + pad);

    // Single point: render as a rounded dot
    if (points.length == 1) {
      final center = at(points[0]);
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
    final firstPoint = at(points[0]);
    path.moveTo(firstPoint.dx, firstPoint.dy);

    if (points.length == 2) {
      final secondPoint = at(points[1]);
      path.lineTo(secondPoint.dx, secondPoint.dy);
    } else {
      for (var i = 1; i < points.length - 1; i++) {
        final pCurrent = at(points[i]);
        final pNext = at(points[i + 1]);
        final midPoint = Offset(
          (pCurrent.dx + pNext.dx) / 2.0,
          (pCurrent.dy + pNext.dy) / 2.0,
        );

        path.quadraticBezierTo(pCurrent.dx, pCurrent.dy, midPoint.dx, midPoint.dy);
      }

      final lastPoint = at(points.last);
      path.lineTo(lastPoint.dx, lastPoint.dy);
    }

    // Render optional neon glow
    if (layer.hasGlow) {
      final glowPaint = Paint()
        ..color = Color(layer.strokeColorValue).withValues(alpha: 0.6)
        ..strokeWidth = layer.strokeWidth + DoodleGeometry.glowExtent
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
    return oldDelegate.layer != layer ||
        oldDelegate.canvasSize != canvasSize ||
        oldDelegate.inLocalBox != inLocalBox;
  }
}
