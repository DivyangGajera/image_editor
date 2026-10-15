import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_editor/features/collage/application/collage_engine.dart';
import 'package:image_editor/features/collage/domain/models/models.dart';

/// Live WYSIWYG preview box dynamically rendering the collage layout,
/// image aspect ratios, cell borders, and margins in real-time.
class CollagePreviewBox extends StatelessWidget {
  const CollagePreviewBox({
    super.key,
    required this.imagePaths,
    required this.config,
    required this.engine,
  });

  final List<String> imagePaths;
  final CollageConfig config;
  final CollageEngine engine;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = config.canvasWidth / config.canvasHeight;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        key: const ValueKey('collage_preview_box'),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xFF161622),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: const Color(0xFF2E2E40),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 12.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: imagePaths.length < 2
            ? _buildEmptyPlaceholder(context)
            : _buildLayout(context),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_mosaic_outlined,
            size: 48.0,
            color: Colors.white.withAlpha(80),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Select 2 to 9 photos',
            style: TextStyle(
              color: Colors.white.withAlpha(160),
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Live layout preview will appear here',
            style: TextStyle(
              color: Colors.white.withAlpha(90),
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    final cells = engine.generateLayout(imagePaths, config);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxW = constraints.maxWidth;
        final boxH = constraints.maxHeight;

        // Scale factors to map canvas coordinates (e.g. 1080) to preview box size
        final scaleX = boxW / config.canvasWidth;
        final scaleY = boxH / config.canvasHeight;
        final scaledBorder = (config.borderWidth * scaleX).clamp(0.0, 15.0);

        return Stack(
          children: cells.map((cell) {
            final cellW = cell.width * scaleX;
            final cellH = cell.height * scaleY;
            final left = (cell.x * boxW) - (cellW / 2.0);
            final top = (cell.y * boxH) - (cellH / 2.0);

            return Positioned(
              left: left,
              top: top,
              width: cellW,
              height: cellH,
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Color(config.borderColorValue),
                ),
                padding: EdgeInsets.all(scaledBorder),
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    color: Color(0xFF222230),
                  ),
                  child: Image.file(
                    File(cell.sourceImagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white38),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
