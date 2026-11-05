import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_editor/features/layers/application/doodle_geometry.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/layers/presentation/widgets/doodle_painter.dart';
import 'package:uuid/uuid.dart';

/// Full-canvas interactive overlay widget for capturing freehand drawing strokes.
///
/// Throttles incoming touch events with an epsilon distance threshold ($\Delta d \ge 3.0$ px)
/// to reduce point density and memory consumption, and emits a completed [DoodleLayer] on stroke finish.
class DoodleCanvasOverlay extends StatefulWidget {
  const DoodleCanvasOverlay({
    super.key,
    required this.canvasSize,
    required this.onDoodleFinished,
    this.strokeColor = Colors.white,
    this.strokeWidth = 4.0,
    this.hasGlow = false,
    this.isEnabled = true,
  });

  /// The active dimensions of the canvas area.
  final Size canvasSize;

  /// Callback emitted when a stroke gesture completes.
  final ValueChanged<DoodleLayer> onDoodleFinished;

  /// Active stroke color for current drawing session.
  final Color strokeColor;

  /// Active stroke width in pixels.
  final double strokeWidth;

  /// Whether neon glow blur filter is applied to the stroke.
  final bool hasGlow;

  /// Whether drawing interactions are enabled.
  final bool isEnabled;

  /// Minimum euclidean distance in screen pixels required to register a new point.
  static const double epsilonDistanceThreshold = 3.0;

  @override
  State<DoodleCanvasOverlay> createState() => _DoodleCanvasOverlayState();
}

class _DoodleCanvasOverlayState extends State<DoodleCanvasOverlay> {
  final List<List<double>> _currentPoints = <List<double>>[];
  Offset _lastRecordedPoint = Offset.zero;

  void _onPanStart(DragStartDetails details) {
    if (!widget.isEnabled) return;
    if (widget.canvasSize.width <= 0 || widget.canvasSize.height <= 0) return;

    final pos = details.localPosition;
    _lastRecordedPoint = pos;

    final nx = (pos.dx / widget.canvasSize.width).clamp(0.0, 1.0);
    final ny = (pos.dy / widget.canvasSize.height).clamp(0.0, 1.0);

    setState(() {
      _currentPoints
        ..clear()
        ..add(<double>[nx, ny]);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled || _currentPoints.isEmpty) return;
    if (widget.canvasSize.width <= 0 || widget.canvasSize.height <= 0) return;

    final pos = details.localPosition;
    final dx = pos.dx - _lastRecordedPoint.dx;
    final dy = pos.dy - _lastRecordedPoint.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Enforce epsilon threshold to optimize memory and prevent micro-point bloat
    if (distance >= DoodleCanvasOverlay.epsilonDistanceThreshold) {
      _lastRecordedPoint = pos;
      final nx = (pos.dx / widget.canvasSize.width).clamp(0.0, 1.0);
      final ny = (pos.dy / widget.canvasSize.height).clamp(0.0, 1.0);

      setState(() {
        _currentPoints.add(<double>[nx, ny]);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isEnabled || _currentPoints.isEmpty) return;

    final layer = DoodleGeometry.fromCanvasPoints(
      id: const Uuid().v4(),
      canvasPoints: List<List<double>>.from(_currentPoints),
      strokeColorValue: widget.strokeColor.toARGB32(),
      strokeWidth: widget.strokeWidth,
      hasGlow: widget.hasGlow,
    );

    widget.onDoodleFinished(layer);

    setState(() {
      _currentPoints.clear();
      _lastRecordedPoint = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled && _currentPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    // A snapshot of the points: passing the live list would make each new
    // painter equal to the previous one (same list instance), so
    // shouldRepaint returned false and the stroke only appeared on release.
    final inProgressLayer = DoodleLayer(
      id: 'in-progress-doodle',
      x: 0.5,
      y: 0.5,
      points: List<List<double>>.of(_currentPoints),
      strokeColorValue: widget.strokeColor.toARGB32(),
      strokeWidth: widget.strokeWidth,
      hasGlow: widget.hasGlow,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: RepaintBoundary(
        child: CustomPaint(
          size: widget.canvasSize,
          painter: _currentPoints.isNotEmpty
              ? DoodlePainter(
                  layer: inProgressLayer,
                  canvasSize: widget.canvasSize,
                  inLocalBox: false,
                )
              : null,
        ),
      ),
    );
  }
}
