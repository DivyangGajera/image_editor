import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/utils/color_filters.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/layers/layers.dart';

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
      return _renderStickerLayer(context, ref, concreteLayer);
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
            key: const ValueKey('horizontal_flip_transform'),
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
            child: content,
          );
        }

        if (layer.activeFilter != null) {
          final filter = AppColorFilters.getFilterByName(layer.activeFilter);
          if (filter != null) {
            content = ColorFiltered(
              colorFilter: filter,
              child: content,
            );
          }
        }

        return content;
      },
    );
  }

  Widget _renderTextLayer(BuildContext context, TextLayer layer) {
    return TextLayerWidget(layer: layer);
  }

  Widget _renderDoodleLayer(BuildContext context, DoodleLayer layer) {
    return CustomPaint(
      size: DoodleGeometry.localSize(layer, canvasSize),
      painter: DoodlePainter(layer: layer, canvasSize: canvasSize),
    );
  }

  Widget _renderStickerLayer(BuildContext context, WidgetRef ref, StickerLayer layer) {
    final filePath = layer.relativeFilePath;
    if (filePath == null) {
      return Image.asset(
        layer.assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildPlaceholder(Icons.emoji_emotions_outlined),
      );
    }

    return FutureBuilder<File>(
      future: ref.watch(projectRepositoryProvider).resolveRelativePath(filePath),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null || !file.existsSync()) {
          return _buildPlaceholder(Icons.emoji_emotions_outlined);
        }
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildPlaceholder(Icons.broken_image_outlined),
        );
      },
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      width: 120.0,
      height: 120.0,
      decoration: BoxDecoration(
        // Neutral greys stay visible on white and on photo backgrounds.
        color: const Color(0x14000000),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0x33000000), width: 1.0),
      ),
      child: Center(
        child: Icon(icon, size: 48.0, color: const Color(0x8A000000)),
      ),
    );
  }
}
