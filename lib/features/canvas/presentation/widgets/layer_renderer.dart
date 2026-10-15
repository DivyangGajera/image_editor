import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Pure presentation widget rendering the visual content of any [CanvasLayer].
class LayerRenderer extends ConsumerWidget {
  const LayerRenderer({
    super.key,
    required this.layer,
    required this.canvasSize,
  });

  final CanvasLayer layer;
  final Size canvasSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concreteLayer = layer;
    if (concreteLayer is ImageLayer) {
      return _renderImageLayer(context, ref, concreteLayer);
    } else if (concreteLayer is TextLayer) {
      return _renderTextLayer(context, concreteLayer);
    } else if (concreteLayer is DoodleLayer) {
      return _renderDoodleLayer(context, concreteLayer);
    } else if (concreteLayer is StickerLayer) {
      return _renderStickerLayer(context, concreteLayer);
    }
    return const SizedBox.shrink();
  }

  Widget _renderImageLayer(BuildContext context, WidgetRef ref, ImageLayer layer) {
    final repo = ref.watch(projectRepositoryProvider);

    return FutureBuilder<File>(
      future: repo.resolveRelativePath(layer.relativeImagePath),
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.hasData && snapshot.data!.existsSync()) {
          content = Image.file(
            snapshot.data!,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _buildPlaceholder(Icons.broken_image_outlined),
          );
        } else {
          content = _buildPlaceholder(Icons.photo_outlined);
        }

        if (layer.isFlippedHorizontally) {
          content = Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
            child: content,
          );
        }

        return content;
      },
    );
  }

  Widget _renderTextLayer(BuildContext context, TextLayer layer) {
    final textStyle = TextStyle(
      fontSize: layer.fontSize,
      color: Color(layer.textColorValue),
      fontFamily: layer.fontFamily,
      fontWeight: layer.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: layer.isItalic ? FontStyle.italic : FontStyle.normal,
      shadows: layer.shadowColorValue != null
          ? <Shadow>[
              Shadow(
                color: Color(layer.shadowColorValue!),
                blurRadius: 4.0,
                offset: const Offset(2.0, 2.0),
              ),
            ]
          : null,
    );

    Widget textWidget = Text(
      layer.text,
      style: textStyle,
      textAlign: TextAlign.center,
    );

    if (layer.boxColorValue != null) {
      textWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Color(layer.boxColorValue!),
          borderRadius: BorderRadius.circular(layer.boxBorderRadius),
        ),
        child: textWidget,
      );
    }

    return textWidget;
  }

  Widget _renderDoodleLayer(BuildContext context, DoodleLayer layer) {
    return CustomPaint(
      size: canvasSize,
      painter: DoodlePainter(layer: layer, canvasSize: canvasSize),
    );
  }

  Widget _renderStickerLayer(BuildContext context, StickerLayer layer) {
    return Image.asset(
      layer.assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _buildPlaceholder(Icons.emoji_emotions_outlined),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      width: 120.0,
      height: 120.0,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.white24, width: 1.0),
      ),
      child: Center(
        child: Icon(icon, size: 48.0, color: Colors.white70),
      ),
    );
  }
}

/// Custom painter for rendering vector doodle paths.
class DoodlePainter extends CustomPainter {
  const DoodlePainter({
    required this.layer,
    required this.canvasSize,
  });

  final DoodleLayer layer;
  final Size canvasSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (layer.points.isEmpty) return;

    final path = Path();
    var isFirst = true;

    for (final point in layer.points) {
      if (point.length < 2) continue;
      // Points are normalized (0.0 - 1.0) relative to canvasSize
      final px = point[0] * canvasSize.width;
      final py = point[1] * canvasSize.height;

      if (isFirst) {
        path.moveTo(px, py);
        isFirst = false;
      } else {
        path.lineTo(px, py);
      }
    }

    if (layer.hasGlow) {
      final glowPaint = Paint()
        ..color = Color(layer.strokeColorValue).withValues(alpha: 0.5)
        ..strokeWidth = layer.strokeWidth + 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawPath(path, glowPaint);
    }

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
