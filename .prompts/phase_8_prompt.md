Implement the Doodle layer using scalable vector paths.

1. In lib/features/layers/presentation/widgets/doodle_painter.dart:
 - Implement CustomPainter that renders a list of normalized coordinates as smoothed Bezier curves (Path.quadraticBezierTo).
 - Support strokeWidth, strokeColor, and optional glow effect using MaskFilter.blur(BlurStyle.solid, sigma).
2. In lib/features/layers/presentation/widgets/doodle_canvas_overlay.dart:
 - Capture touch moves via onPanUpdate.
 - Performance Optimization: Apply an epsilon distance threshold ($\Delta d \ge 3.0$ px) before registering a new point to avoid memory bloat.
 - On onPanEnd, finalize the stroke, package it into a DoodleLayer, and push it to CanvasNotifier