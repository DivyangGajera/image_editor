import 'package:flutter/rendering.dart';

/// Utility calculating coordinate mappings between the screen viewport
/// and normalized canvas coordinates `(0.0 - 1.0)`.
abstract final class CanvasCoordinateConverter {
  /// Computes the exact destination rectangle of the canvas letterboxed within the viewport.
  static Rect calculateFittedCanvasRect({
    required Size viewportSize,
    required Size canvasSize,
    BoxFit fit = BoxFit.contain,
  }) {
    if (viewportSize.isEmpty || canvasSize.isEmpty) {
      return Rect.zero;
    }

    final fittedSizes = applyBoxFit(fit, canvasSize, viewportSize);
    final destinationSize = fittedSizes.destination;
    final dx = (viewportSize.width - destinationSize.width) / 2.0;
    final dy = (viewportSize.height - destinationSize.height) / 2.0;

    return Rect.fromLTWH(dx, dy, destinationSize.width, destinationSize.height);
  }

  /// Converts a screen pixel offset into normalized canvas coordinates `(0.0 - 1.0)`.
  ///
  /// `(0.0, 0.0)` represents the top-left canvas corner and `(1.0, 1.0)` represents
  /// the bottom-right corner.
  static Offset screenToCanvasNormalized({
    required Offset screenOffset,
    required Size viewportSize,
    required Size canvasSize,
    BoxFit fit = BoxFit.contain,
  }) {
    final canvasRect = calculateFittedCanvasRect(
      viewportSize: viewportSize,
      canvasSize: canvasSize,
      fit: fit,
    );

    if (canvasRect.width <= 0 || canvasRect.height <= 0) {
      return Offset.zero;
    }

    final normalizedX = (screenOffset.dx - canvasRect.left) / canvasRect.width;
    final normalizedY = (screenOffset.dy - canvasRect.top) / canvasRect.height;

    return Offset(normalizedX, normalizedY);
  }

  /// Converts normalized canvas coordinates `(0.0 - 1.0)` back to viewport pixel coordinates.
  static Offset canvasNormalizedToScreen({
    required Offset normalizedOffset,
    required Size viewportSize,
    required Size canvasSize,
    BoxFit fit = BoxFit.contain,
  }) {
    final canvasRect = calculateFittedCanvasRect(
      viewportSize: viewportSize,
      canvasSize: canvasSize,
      fit: fit,
    );

    final screenX = canvasRect.left + (normalizedOffset.dx * canvasRect.width);
    final screenY = canvasRect.top + (normalizedOffset.dy * canvasRect.height);

    return Offset(screenX, screenY);
  }

  /// Checks whether a screen touch point falls within the letterboxed canvas boundaries.
  static bool isWithinCanvas({
    required Offset screenOffset,
    required Size viewportSize,
    required Size canvasSize,
    BoxFit fit = BoxFit.contain,
  }) {
    final canvasRect = calculateFittedCanvasRect(
      viewportSize: viewportSize,
      canvasSize: canvasSize,
      fit: fit,
    );

    return canvasRect.contains(screenOffset);
  }
}
