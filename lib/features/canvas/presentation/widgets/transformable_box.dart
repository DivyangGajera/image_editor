import 'package:flutter/material.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Interactive wrapper handling single/multi-touch pan, pinch-to-scale,
/// and twist-to-rotate gestures around a [CanvasLayer].
///
/// Renders an active selection border, 4 corner anchors, and an accessible
/// delete button when [isSelected] is true.
class TransformableBox extends StatefulWidget {
  const TransformableBox({
    super.key,
    required this.layer,
    required this.isSelected,
    required this.canvasSize,
    required this.onSelect,
    required this.onTransformUpdate,
    required this.onDelete,
    required this.child,
  });

  final CanvasLayer layer;
  final bool isSelected;
  final Size canvasSize;
  final VoidCallback onSelect;
  final void Function({
    double? x,
    double? y,
    double? scale,
    double? rotation,
    bool recordHistory,
  }) onTransformUpdate;
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

  double _currentX = 0.5;
  double _currentY = 0.5;
  double _currentScale = 1.0;
  double _currentRotation = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Convert normalized coordinates (0.0 - 1.0) to pixel position on canvas
    final pixelX = widget.layer.x * widget.canvasSize.width;
    final pixelY = widget.layer.y * widget.canvasSize.height;

    return Positioned(
      left: pixelX,
      top: pixelY,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.rotate(
          angle: widget.layer.rotation,
          child: Transform.scale(
            scale: widget.layer.scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gesture detector wraps the layer content with padding so controls stay within hit-test bounds
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onSelect,
                    onScaleStart: (details) {
                      widget.onSelect();
                      _startFocalPoint = details.focalPoint;
                      _startX = _currentX = widget.layer.x;
                      _startY = _currentY = widget.layer.y;
                      _startScale = _currentScale = widget.layer.scale;
                      _startRotation = _currentRotation = widget.layer.rotation;
                    },
                    onScaleUpdate: (details) {
                      if (widget.canvasSize.width <= 0 || widget.canvasSize.height <= 0) return;

                      final deltaX = (details.focalPoint.dx - _startFocalPoint.dx) / widget.canvasSize.width;
                      final deltaY = (details.focalPoint.dy - _startFocalPoint.dy) / widget.canvasSize.height;

                      _currentX = (_startX + deltaX).clamp(-0.5, 1.5);
                      _currentY = (_startY + deltaY).clamp(-0.5, 1.5);
                      _currentScale = (_startScale * details.scale).clamp(0.1, 10.0);
                      _currentRotation = _startRotation + details.rotation;

                      widget.onTransformUpdate(
                        x: _currentX,
                        y: _currentY,
                        scale: _currentScale,
                        rotation: _currentRotation,
                        recordHistory: false, // Don't flood history on micro-updates
                      );
                    },
                    onScaleEnd: (details) {
                      // Record final state to history
                      widget.onTransformUpdate(
                        x: _currentX,
                        y: _currentY,
                        scale: _currentScale,
                        rotation: _currentRotation,
                        recordHistory: true,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: widget.isSelected
                            ? Border.all(color: primaryColor, width: 2.0)
                            : null,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),

                // Selection controls: 4 corner anchors & delete button within Stack bounds
                if (widget.isSelected) ...[
                  // Top-Left Anchor
                  Positioned(
                    left: 8.0,
                    top: 8.0,
                    child: _buildCornerAnchor(primaryColor),
                  ),

                  // Top-Right Delete Button
                  Positioned(
                    right: 2.0,
                    top: 2.0,
                    child: _buildDeleteButton(),
                  ),

                  // Bottom-Left Anchor
                  Positioned(
                    left: 8.0,
                    bottom: 8.0,
                    child: _buildCornerAnchor(primaryColor),
                  ),

                  // Bottom-Right Anchor
                  Positioned(
                    right: 8.0,
                    bottom: 8.0,
                    child: _buildCornerAnchor(primaryColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCornerAnchor(Color color) {
    return Container(
      width: 16.0,
      height: 16.0,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Semantics(
      button: true,
      label: 'Delete Layer',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDelete,
        child: Container(
          width: 28.0,
          height: 28.0,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444), // Crimson red
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 4.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.close,
              size: 16.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
