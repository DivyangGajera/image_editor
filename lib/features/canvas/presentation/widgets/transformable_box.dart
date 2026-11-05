import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/canvas/application/canvas_coordinate_converter.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Interactive wrapper placing a [CanvasLayer] on the canvas and handling
/// single-finger drag, two-finger pinch-to-scale and twist-to-rotate, and a
/// corner handle for one-finger rotate and resize.
///
/// The box lives in *canvas units* (inside the canvas `FittedBox`), so pointer
/// movement measured in screen pixels is converted with [viewScale]. Selection
/// chrome (border, delete button) is counter-scaled so it keeps a constant
/// on-screen size regardless of zoom or layer scale.
///
/// Gestures are reported as begin → preview… → end so the owner can record a
/// single undo step per gesture.
class TransformableBox extends StatefulWidget {
  const TransformableBox({
    super.key,
    required this.layer,
    required this.isSelected,
    required this.canvasSize,
    required this.viewScale,
    required this.onSelect,
    required this.onInteractionStart,
    required this.onTransformPreview,
    required this.onInteractionEnd,
    required this.onDelete,
    required this.child,
  });

  /// Smallest and largest scale a gesture may produce.
  static const double minScale = 0.05;
  static const double maxScale = 20.0;

  /// On-screen size of the selection chrome, in logical pixels.
  static const double chromeHitSize = 28.0;

  /// Rotations within this many radians of a right angle snap onto it.
  static const double rotationSnapTolerance = 0.05;

  /// Snaps [rotation] (radians) to the nearest multiple of 90° when it is
  /// within [rotationSnapTolerance] of it, so layers are easy to straighten.
  static double snapRotation(double rotation) {
    const quarterTurn = math.pi / 2;
    final nearest = (rotation / quarterTurn).roundToDouble() * quarterTurn;
    return (rotation - nearest).abs() <= rotationSnapTolerance ? nearest : rotation;
  }

  /// Scale and rotation produced by dragging the corner handle from
  /// [startVector] to [currentVector], both measured from the layer center.
  static ({double scale, double rotation}) handleTransform({
    required Offset startVector,
    required Offset currentVector,
    required double startScale,
    required double startRotation,
  }) {
    if (startVector.distance < 1.0) {
      return (scale: startScale, rotation: startRotation);
    }
    final scale = (startScale * currentVector.distance / startVector.distance)
        .clamp(minScale, maxScale);
    final rotation = snapRotation(
      startRotation + (currentVector.direction - startVector.direction),
    );
    return (scale: scale, rotation: rotation);
  }

  final CanvasLayer layer;
  final bool isSelected;
  final Size canvasSize;

  /// Screen logical pixels per canvas unit (see [CanvasCoordinateConverter.fitScale]).
  final double viewScale;

  final VoidCallback onSelect;
  final VoidCallback onInteractionStart;
  final void Function({double? x, double? y, double? scale, double? rotation})
      onTransformPreview;
  final VoidCallback onInteractionEnd;
  final VoidCallback onDelete;
  final Widget child;

  @override
  State<TransformableBox> createState() => _TransformableBoxState();
}

class _TransformableBoxState extends State<TransformableBox> {
  Offset _startFocalPoint = Offset.zero;
  double _startX = 0.5;
  double _startY = 0.5;
  double _startScale = 1.0;
  double _startRotation = 0.0;

  /// Layer center and pointer vector captured when a handle drag starts.
  Offset _handleCenter = Offset.zero;
  Offset _handleStartVector = Offset.zero;

  /// Converts a length in screen pixels to the box's local (pre-scale) units.
  double _screenToLocal(double length) {
    final factor = widget.viewScale * widget.layer.scale;
    return factor > 0 ? length / factor : length;
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startFocalPoint = details.focalPoint;
    _startX = widget.layer.x;
    _startY = widget.layer.y;
    _startScale = widget.layer.scale;
    _startRotation = widget.layer.rotation;
    widget.onInteractionStart();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final delta = CanvasCoordinateConverter.screenDeltaToNormalized(
      screenDelta: details.focalPoint - _startFocalPoint,
      canvasSize: widget.canvasSize,
      viewScale: widget.viewScale,
    );

    widget.onTransformPreview(
      x: (_startX + delta.dx).clamp(-0.5, 1.5),
      y: (_startY + delta.dy).clamp(-0.5, 1.5),
      scale: (_startScale * details.scale)
          .clamp(TransformableBox.minScale, TransformableBox.maxScale),
      rotation: TransformableBox.snapRotation(_startRotation + details.rotation),
    );
  }

  /// The layer center in global coordinates. The box's render origin sits at
  /// the layer center; [FractionalTranslation] only shifts the painted child.
  Offset _layerCenterGlobal() {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  }

  void _onHandleStart(DragStartDetails details) {
    _handleCenter = _layerCenterGlobal();
    _handleStartVector = details.globalPosition - _handleCenter;
    _startScale = widget.layer.scale;
    _startRotation = widget.layer.rotation;
    widget.onInteractionStart();
  }

  void _onHandleUpdate(DragUpdateDetails details) {
    final result = TransformableBox.handleTransform(
      startVector: _handleStartVector,
      currentVector: details.globalPosition - _handleCenter,
      startScale: _startScale,
      startRotation: _startRotation,
    );
    widget.onTransformPreview(scale: result.scale, rotation: result.rotation);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final layer = widget.layer;
    final locked = layer.isLocked;
    final pad = _screenToLocal(TransformableBox.chromeHitSize / 2.0);
    final borderWidth = _screenToLocal(2.0);

    return Positioned(
      left: layer.x * widget.canvasSize.width,
      top: layer.y * widget.canvasSize.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.rotate(
          angle: layer.rotation,
          child: Transform.scale(
            scale: layer.scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.all(pad),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onSelect,
                    // A locked layer can be selected (to unlock it) but not moved.
                    onScaleStart: locked ? null : _onScaleStart,
                    onScaleUpdate: locked ? null : _onScaleUpdate,
                    onScaleEnd: locked ? null : (_) => widget.onInteractionEnd(),
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        border: widget.isSelected
                            ? Border.all(color: locked ? colors.outline : colors.primary, width: borderWidth)
                            : null,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
                if (widget.isSelected && locked)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: _ScreenSized(
                      factor: _screenToLocal(1.0),
                      child: _ChromeButton(
                        key: const ValueKey('locked_badge'),
                        semanticsLabel: 'Layer is locked',
                        icon: Icons.lock_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (widget.isSelected && !locked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _ScreenSized(
                      factor: _screenToLocal(1.0),
                      child: GestureDetector(
                        key: const ValueKey('rotate_scale_handle'),
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _onHandleStart,
                        onPanUpdate: _onHandleUpdate,
                        onPanEnd: (_) => widget.onInteractionEnd(),
                        child: _ChromeButton(
                          semanticsLabel: 'Rotate and resize layer',
                          icon: Icons.open_in_full_rounded,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                if (widget.isSelected && !locked)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: _ScreenSized(
                      factor: _screenToLocal(1.0),
                      child: _ChromeButton(
                        semanticsLabel: 'Delete Layer',
                        icon: Icons.close,
                        color: AppTheme.danger,
                        onTap: widget.onDelete,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders [child] at [factor] times its laid-out size, used to keep selection
/// chrome a constant size on screen inside scaled canvas content.
class _ScreenSized extends StatelessWidget {
  const _ScreenSized({required this.factor, required this.child});

  final double factor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const size = TransformableBox.chromeHitSize;
    return SizedBox(
      width: size * factor,
      height: size * factor,
      child: FittedBox(
        child: SizedBox(width: size, height: size, child: child),
      ),
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    super.key,
    required this.semanticsLabel,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String semanticsLabel;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.0),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: Offset(0, 1)),
            ],
          ),
          child: Center(child: Icon(icon, size: 16.0, color: Colors.white)),
        ),
      ),
    );
  }
}
