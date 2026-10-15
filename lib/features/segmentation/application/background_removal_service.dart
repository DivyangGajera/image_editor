import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/layers/domain/models/image_layer.dart';
import 'package:image_editor/features/segmentation/application/pixel_cutout_processor.dart';
import 'package:uuid/uuid.dart';

/// Orchestrates offline background extraction using Google ML Kit Selfie Segmentation
/// and concurrency-isolated raw pixel alpha feathering in a background Isolate.
class BackgroundRemovalService {
  BackgroundRemovalService({
    required this.projectRepository,
    this.pixelCutoutProcessor = const PixelCutoutProcessor(),
    this.segmenterFactory,
  });

  /// Repository for persistent sandbox image storage.
  final ProjectRepository projectRepository;

  /// Worker executing pixel calculations inside a background isolate.
  final PixelCutoutProcessor pixelCutoutProcessor;

  /// Optional factory callback to create/inject [SelfieSegmenter] (useful for testing).
  final SelfieSegmenter Function()? segmenterFactory;

  /// Extracts the person / foreground subject from [sourceImagePath],
  /// writes the transparent PNG cutout to the project sandbox, and returns a new [ImageLayer].
  Future<ImageLayer> removeBackground({
    required String sourceImagePath,
    required String projectId,
    double confidenceThreshold = 0.7,
    bool smoothEdges = true,
  }) async {
    final imageFile = File(sourceImagePath);
    if (!await imageFile.exists()) {
      throw ArgumentError('Source image file does not exist at: $sourceImagePath');
    }

    final imageBytes = await imageFile.readAsBytes();

    // Initialize ML Kit SelfieSegmenter in single-image mode
    final segmenter = segmenterFactory != null
        ? segmenterFactory!()
        : SelfieSegmenter(
            mode: SegmenterMode.single,
            enableRawSizeMask: true,
          );

    final SegmentationMask? mask;
    try {
      final inputImage = InputImage.fromFilePath(sourceImagePath);
      mask = await segmenter.processImage(inputImage);
    } finally {
      await segmenter.close();
    }

    if (mask == null) {
      throw StateError('Selfie segmenter returned null mask for image at $sourceImagePath');
    }

    // Process pixel-level alpha blending and edge smoothing in background Isolate
    final cutoutBytes = await pixelCutoutProcessor.processCutout(
      CutoutProcessingParams(
        imageBytes: imageBytes,
        maskConfidences: mask.confidences,
        maskWidth: mask.width,
        maskHeight: mask.height,
        confidenceThreshold: confidenceThreshold,
        smoothEdges: smoothEdges,
      ),
    );

    // Save cutout into sandbox directory
    final filename = 'cutout_${const Uuid().v4()}.png';
    final relativePath = await projectRepository.saveLayerImage(
      projectId,
      cutoutBytes,
      filename,
    );

    return ImageLayer(
      id: const Uuid().v4(),
      x: 0.5,
      y: 0.5,
      scale: 1.0,
      rotation: 0.0,
      zIndex: 0,
      isVisible: true,
      relativeImagePath: relativePath,
    );
  }
}

/// Riverpod provider for [BackgroundRemovalService].
final backgroundRemovalServiceProvider = Provider<BackgroundRemovalService>((ref) {
  final projectRepo = ref.watch(projectRepositoryProvider);
  return BackgroundRemovalService(projectRepository: projectRepo);
});
