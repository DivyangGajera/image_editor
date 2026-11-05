import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/layers/domain/models/image_layer.dart';
import 'package:image_editor/features/segmentation/application/pixel_cutout_processor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'background_removal_service.g.dart';

/// Why a background could not be removed, worded for the user.
class BackgroundRemovalException implements Exception {
  const BackgroundRemovalException(this.message);
  final String message;

  static const BackgroundRemovalException noSubject = BackgroundRemovalException(
    'No clear subject was found. Try a photo where the subject stands out from the background.',
  );

  static const BackgroundRemovalException modelNotReady = BackgroundRemovalException(
    'The background remover is still being set up by Google Play services. '
    'Connect to the internet once, wait a moment and try again.',
  );

  @override
  String toString() => 'BackgroundRemovalException: $message';
}

/// Produces a row-major foreground confidence mask (one value per pixel of
/// the image file) for the main subject of an image.
abstract interface class SubjectMasker {
  Future<List<double>> maskFor(String imagePath);
}

/// [SubjectMasker] backed by ML Kit Subject Segmentation, which finds the
/// main subject of a photo: people, pets, and objects such as products,
/// bottles or cars. Runs on device; the model is delivered by Google Play
/// services (requested at install time via the manifest).
class MlKitSubjectMasker implements SubjectMasker {
  const MlKitSubjectMasker();

  @override
  Future<List<double>> maskFor(String imagePath) async {
    final segmenter = SubjectSegmenter(
      options: SubjectSegmenterOptions(
        enableForegroundBitmap: false,
        enableForegroundConfidenceMask: true,
        enableMultipleSubjects: SubjectResultOptions(
          enableConfidenceMask: false,
          enableSubjectBitmap: false,
        ),
      ),
    );
    try {
      final result = await segmenter.processImage(InputImage.fromFilePath(imagePath));
      final mask = result.foregroundConfidenceMask;
      if (mask == null || mask.isEmpty) throw BackgroundRemovalException.noSubject;
      return mask;
    } on PlatformException catch (error) {
      final details = '${error.code} ${error.message}'.toLowerCase();
      if (details.contains('download') || details.contains('module')) {
        throw BackgroundRemovalException.modelNotReady;
      }
      rethrow;
    } finally {
      await segmenter.close();
    }
  }
}

/// Removes the background behind the main subject of an image, entirely on
/// device. Pixel work runs in a background isolate.
class BackgroundRemovalService {
  BackgroundRemovalService({
    required this.projectRepository,
    this.pixelCutoutProcessor = const PixelCutoutProcessor(),
    SubjectMasker? masker,
    Future<Directory> Function()? getTempDir,
  })  : _masker = masker ?? const MlKitSubjectMasker(),
        _getTempDir = getTempDir ?? getTemporaryDirectory;

  /// Repository for persistent sandbox image storage.
  final ProjectRepository projectRepository;

  /// Worker executing pixel calculations inside a background isolate.
  final PixelCutoutProcessor pixelCutoutProcessor;

  final SubjectMasker _masker;
  final Future<Directory> Function() _getTempDir;

  /// Pixels below this foreground confidence become transparent.
  static const double confidenceThreshold = 0.5;

  /// Returns PNG bytes of [imageBytes] with everything but the main subject
  /// made transparent. Throws [BackgroundRemovalException] if nothing usable
  /// is found or the model is not available yet.
  Future<Uint8List> cutOut(Uint8List imageBytes) async {
    // ML Kit reads images from files.
    final temp = File(p.join((await _getTempDir()).path, 'cutout_src_${const Uuid().v4()}'));
    await temp.writeAsBytes(imageBytes, flush: true);
    try {
      return await cutOutFile(temp.path, imageBytes: imageBytes);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  /// Like [cutOut] for an image that is already a file.
  Future<Uint8List> cutOutFile(String imagePath, {Uint8List? imageBytes}) async {
    final bytes = imageBytes ?? await File(imagePath).readAsBytes();
    final mask = await _masker.maskFor(imagePath);
    try {
      return await pixelCutoutProcessor.processCutout(
        CutoutProcessingParams(
          imageBytes: bytes,
          maskConfidences: mask,
          confidenceThreshold: confidenceThreshold,
        ),
      );
    } on NoSubjectFoundException {
      throw BackgroundRemovalException.noSubject;
    }
  }

  /// Cuts out the subject of the project image at [sourceImagePath], saves it
  /// into the project and returns a new [ImageLayer] for it.
  Future<ImageLayer> removeBackground({
    required String sourceImagePath,
    required String projectId,
  }) async {
    if (!await File(sourceImagePath).exists()) {
      throw ArgumentError('Source image file does not exist at: $sourceImagePath');
    }
    final cutoutBytes = await cutOutFile(sourceImagePath);
    final relativePath = await projectRepository.saveLayerImage(
      projectId,
      cutoutBytes,
      'cutout_${const Uuid().v4()}.png',
    );

    return ImageLayer(
      id: const Uuid().v4(),
      x: 0.5,
      y: 0.5,
      relativeImagePath: relativePath,
    );
  }
}

/// App-wide singleton [BackgroundRemovalService].
@Riverpod(keepAlive: true)
BackgroundRemovalService backgroundRemovalService(Ref ref) {
  return BackgroundRemovalService(
    projectRepository: ref.watch(projectRepositoryProvider),
  );
}
