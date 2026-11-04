import 'package:flutter/material.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/canvas/application/canvas_coordinate_converter.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Interactive wrapper placing a [CanvasLayer] on the canvas and handling
/// single-finger drag plus two-finger pinch-to-scale and twist-to-rotate.
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
      rotation: _startRotation + details.rotation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final layer = widget.layer;
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
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    onScaleEnd: (_) => widget.onInteractionEnd(),
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        border: widget.isSelected
                            ? Border.all(color: colors.primary, width: borderWidth)
                            : null,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
                if (widget.isSelected)
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
