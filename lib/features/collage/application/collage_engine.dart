import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/collage/domain/models/models.dart';
import 'package:image_editor/features/layers/domain/models/image_layer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'collage_engine.g.dart';

/// Parameters passed to the background Isolate for framing and cropping a collage cell.
class FramedCellParams {
  const FramedCellParams({
    required this.sourceBytes,
    required this.targetWidth,
    required this.targetHeight,
    required this.borderWidth,
    required this.borderColorValue,
  });

  final Uint8List sourceBytes;
  final int targetWidth;
  final int targetHeight;
  final int borderWidth;
  final int borderColorValue;
}

/// Core computational engine calculating layout positioning and framing
/// for collages and filmstrips.
class CollageEngine {
  const CollageEngine({
    required this.projectRepository,
  });

  final ProjectRepository projectRepository;

  /// Calculates a horizontal filmstrip layout where all images are placed
  /// side-by-side across the canvas width.
  List<CollageCell> horizontalStrip(
    List<String> imagePaths,
    double spacing, {
    double outerMargin = 16.0,
    double canvasWidth = AppConstants.defaultCanvasWidth,
    double canvasHeight = AppConstants.defaultCanvasWidth,
  }) {
    if (imagePaths.isEmpty) return const [];

    final int count = imagePaths.length;
    final double availableWidth =
        canvasWidth - (outerMargin * 2) - ((count - 1) * spacing);
    final double cellWidth = (availableWidth / count).clamp(1.0, canvasWidth);
    final double cellHeight =
        (canvasHeight - (outerMargin * 2)).clamp(1.0, canvasHeight);

    final List<CollageCell> cells = [];
    for (int i = 0; i < count; i++) {
      final double pixelLeft = outerMargin + (i * (cellWidth + spacing));
      final double pixelTop = outerMargin;

      final double centerX = (pixelLeft + (cellWidth / 2.0)) / canvasWidth;
      final double centerY = (pixelTop + (cellHeight / 2.0)) / canvasHeight;

      cells.add(
        CollageCell(
          x: centerX,
          y: centerY,
          width: cellWidth,
          height: cellHeight,
          zIndex: i,
          sourceImagePath: imagePaths[i],
        ),
      );
    }
    return cells;
  }

  /// Calculates a vertical filmstrip layout where all images are stacked
  /// vertically down the canvas height.
  List<CollageCell> verticalStrip(
    List<String> imagePaths,
    double spacing, {
    double outerMargin = 16.0,
    double canvasWidth = AppConstants.defaultCanvasWidth,
    double canvasHeight = AppConstants.defaultCanvasWidth,
  }) {
    if (imagePaths.isEmpty) return const [];

    final int count = imagePaths.length;
    final double availableHeight =
        canvasHeight - (outerMargin * 2) - ((count - 1) * spacing);
    final double cellHeight = (availableHeight / count).clamp(1.0, canvasHeight);
    final double cellWidth =
        (canvasWidth - (outerMargin * 2)).clamp(1.0, canvasWidth);

    final List<CollageCell> cells = [];
    for (int i = 0; i < count; i++) {
      final double pixelLeft = outerMargin;
      final double pixelTop = outerMargin + (i * (cellHeight + spacing));

      final double centerX = (pixelLeft + (cellWidth / 2.0)) / canvasWidth;
      final double centerY = (pixelTop + (cellHeight / 2.0)) / canvasHeight;

      cells.add(
        CollageCell(
          x: centerX,
          y: centerY,
          width: cellWidth,
          height: cellHeight,
          zIndex: i,
          sourceImagePath: imagePaths[i],
        ),
      );
    }
    return cells;
  }

  /// Calculates an MxN grid matrix layout where images fill cells row-by-row.
  List<CollageCell> gridMatrix(
    List<String> imagePaths,
    int rows,
    int cols,
    double spacing, {
    double outerMargin = 16.0,
    double canvasWidth = AppConstants.defaultCanvasWidth,
    double canvasHeight = AppConstants.defaultCanvasWidth,
  }) {
    if (imagePaths.isEmpty || rows <= 0 || cols <= 0) return const [];

    final double availableWidth =
        canvasWidth - (outerMargin * 2) - ((cols - 1) * spacing);
    final double cellWidth = (availableWidth / cols).clamp(1.0, canvasWidth);

    final double availableHeight =
        canvasHeight - (outerMargin * 2) - ((rows - 1) * spacing);
    final double cellHeight = (availableHeight / rows).clamp(1.0, canvasHeight);

    final List<CollageCell> cells = [];
    final int maxImages = rows * cols;
    final int count = imagePaths.length < maxImages ? imagePaths.length : maxImages;

    for (int i = 0; i < count; i++) {
      final int r = i ~/ cols;
      final int c = i % cols;

      final double pixelLeft = outerMargin + (c * (cellWidth + spacing));
      final double pixelTop = outerMargin + (r * (cellHeight + spacing));

      final double centerX = (pixelLeft + (cellWidth / 2.0)) / canvasWidth;
      final double centerY = (pixelTop + (cellHeight / 2.0)) / canvasHeight;

      cells.add(
        CollageCell(
          x: centerX,
          y: centerY,
          width: cellWidth,
          height: cellHeight,
          zIndex: i,
          sourceImagePath: imagePaths[i],
        ),
      );
    }
    return cells;
  }

  /// Master routing method generating cell coordinates based on the given [config].
  List<CollageCell> generateLayout(List<String> imagePaths, CollageConfig config) {
    if (imagePaths.isEmpty) return const [];

    switch (config.layoutType) {
      case CollageLayoutType.horizontalStrip:
        return horizontalStrip(
          imagePaths,
          config.spacing,
          outerMargin: config.outerMargin,
          canvasWidth: config.canvasWidth,
          canvasHeight: config.canvasHeight,
        );
      case CollageLayoutType.verticalStrip:
        return verticalStrip(
          imagePaths,
          config.spacing,
          outerMargin: config.outerMargin,
          canvasWidth: config.canvasWidth,
          canvasHeight: config.canvasHeight,
        );
      case CollageLayoutType.gridMatrix:
        final (r, c) = _resolveGridDimensions(imagePaths.length, config.rows, config.cols);
        return gridMatrix(
          imagePaths,
          r,
          c,
          config.spacing,
          outerMargin: config.outerMargin,
          canvasWidth: config.canvasWidth,
          canvasHeight: config.canvasHeight,
        );
    }
  }

  /// Automatically deduces balanced rows and columns if the requested grid dimensions
  /// do not accommodate the image count.
  (int, int) _resolveGridDimensions(int count, int preferredRows, int preferredCols) {
    if (preferredRows * preferredCols >= count && preferredRows > 0 && preferredCols > 0) {
      return (preferredRows, preferredCols);
    }

    if (count <= 2) return (1, 2);
    if (count == 3) return (1, 3);
    if (count == 4) return (2, 2);
    if (count <= 6) return (2, 3);
    return (3, 3);
  }

  /// Offloads cell cropping, resizing, and border framing to a background Isolate.
  Future<Uint8List> processCellInIsolate(FramedCellParams params) {
    return Isolate.run(() => executeCellProcessing(params));
  }

  /// Top-level Isolate execution function performing pixel resizing and framing.
  static Uint8List executeCellProcessing(FramedCellParams params) {
    final decoded = img.decodeImage(params.sourceBytes);
    if (decoded == null) {
      throw ArgumentError('Failed to decode source image.');
    }

    final int borderWidth = params.borderWidth;
    final int targetWidth = params.targetWidth;
    final int targetHeight = params.targetHeight;

    final int innerWidth = (targetWidth - (borderWidth * 2)).clamp(1, targetWidth);
    final int innerHeight = (targetHeight - (borderWidth * 2)).clamp(1, targetHeight);

    // Aspect-ratio cover resize and center crop
    final srcRatio = decoded.width / decoded.height;
    final targetRatio = innerWidth / innerHeight;

    int resizeW;
    int resizeH;
    if (srcRatio > targetRatio) {
      resizeH = innerHeight;
      resizeW = (innerHeight * srcRatio).round();
    } else {
      resizeW = innerWidth;
      resizeH = (innerWidth / srcRatio).round();
    }

    final scaled = img.copyResize(decoded, width: resizeW, height: resizeH);
    final cropX = ((resizeW - innerWidth) / 2).round().clamp(0, resizeW - innerWidth);
    final cropY = ((resizeH - innerHeight) / 2).round().clamp(0, resizeH - innerHeight);
    final cropped = img.copyCrop(scaled, x: cropX, y: cropY, width: innerWidth, height: innerHeight);

    // Create target canvas with border
    final framed = img.Image(width: targetWidth, height: targetHeight, numChannels: 4);

    if (borderWidth > 0) {
      final a = (params.borderColorValue >> 24) & 0xFF;
      final r = (params.borderColorValue >> 16) & 0xFF;
      final g = (params.borderColorValue >> 8) & 0xFF;
      final b = params.borderColorValue & 0xFF;
      framed.clear(img.ColorRgba8(r, g, b, a));
    }

    img.compositeImage(framed, cropped, dstX: borderWidth, dstY: borderWidth);
    return Uint8List.fromList(img.encodePng(framed));
  }

  /// Creates a unified [ProjectModel] with individual [ImageLayer]s representing
  /// each collage cell, stored strictly in project-relative sandbox paths.
  Future<ProjectModel> createCollageProject({
    required List<String> imagePaths,
    required CollageConfig config,
    String? projectTitle,
  }) async {
    if (imagePaths.length < 2 || imagePaths.length > 9) {
      throw ArgumentError('Collage requires between 2 and 9 images. Got: ${imagePaths.length}');
    }

    final projectId = const Uuid().v4();
    final cells = generateLayout(imagePaths, config);
    final List<ImageLayer> layers = [];

    for (int i = 0; i < cells.length; i++) {
      final cell = cells[i];
      final file = File(cell.sourceImagePath);
      if (!await file.exists()) {
        throw ArgumentError('Source image file does not exist: ${cell.sourceImagePath}');
      }

      final sourceBytes = await file.readAsBytes();

      // Process cell with borders in background isolate
      final processedBytes = await processCellInIsolate(
        FramedCellParams(
          sourceBytes: sourceBytes,
          targetWidth: cell.width.round(),
          targetHeight: cell.height.round(),
          borderWidth: config.borderWidth.round(),
          borderColorValue: config.borderColorValue,
        ),
      );

      // Save to project sandbox
      final filename = 'cell_${const Uuid().v4()}.png';
      final relativePath = await projectRepository.saveLayerImage(
        projectId,
        processedBytes,
        filename,
      );

      layers.add(
        ImageLayer(
          id: const Uuid().v4(),
          x: cell.x,
          y: cell.y,
          scale: 1.0,
          rotation: 0.0,
          zIndex: cell.zIndex,
          isVisible: true,
          relativeImagePath: relativePath,
        ),
      );
    }

    final project = ProjectModel(
      id: projectId,
      title: projectTitle ?? 'Collage ${DateTime.now().month}/${DateTime.now().day}',
      canvasWidth: config.canvasWidth,
      canvasHeight: config.canvasHeight,
      layers: layers,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await projectRepository.saveProject(project);
    return project;
  }
}

/// App-wide singleton [CollageEngine].
@Riverpod(keepAlive: true)
CollageEngine collageEngine(Ref ref) {
  return CollageEngine(projectRepository: ref.watch(projectRepositoryProvider));
}
