import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/core/utils/app_logger.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/layers/domain/models/image_layer.dart';
import 'package:image_editor/features/segmentation/application/pixel_cutout_processor.dart';
import 'package:image_editor/features/segmentation/application/subject_model_installer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'background_removal_service.g.dart';

/// Why a background could not be removed, worded for the user. [detail]
/// carries the technical cause of unexpected failures so it can be reported.
class BackgroundRemovalException implements Exception {
  const BackgroundRemovalException(this.message, {this.detail});

  final String message;
  final String? detail;

  static const BackgroundRemovalException noSubject = BackgroundRemovalException(
    'No clear subject was found. Try a photo where the subject stands out from the background.',
  );

  static const BackgroundRemovalException modelNotReady = BackgroundRemovalException(
    'Google Play services is downloading the background remover. '
    'Keep the internet on, wait a minute and try again.',
  );

  /// An unexpected failure, with its technical [detail].
  factory BackgroundRemovalException.failed(String detail) => BackgroundRemovalException(
        'Background removal failed. Please try again.',
        detail: detail,
      );

  @override
  String toString() => 'BackgroundRemovalException: $message${detail == null ? '' : ' ($detail)'}';
}

/// Produces a row-major foreground confidence mask (one value per pixel of
/// the image file) for the main subject of an image.
abstract interface class SubjectMasker {
  Future<List<double>> maskFor(String imagePath);
}

/// [SubjectMasker] backed by ML Kit Subject Segmentation, which finds the
/// main subject of a photo: people, pets, and objects such as products,
/// bottles or cars. Runs on device; the model comes from Google Play services.
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
      if (details.contains('download') || details.contains('module') || details.contains('waiting')) {
        throw BackgroundRemovalException.modelNotReady;
      }
      rethrow;
    } finally {
      await segmenter.close();
    }
  }
}

/// The image handed to ML Kit: upright, at most [maxDimension] px, as a JPEG
/// without EXIF, so its pixel size (and so the mask size) is known exactly.
class SegmentationInput {
  const SegmentationInput(this.jpegBytes, this.width, this.height);
  final Uint8List jpegBytes;
  final int width;
  final int height;

  /// Longest edge of the image analysed by ML Kit. The mask is scaled back
  /// up smoothly, so this keeps memory and time low without visible loss.
  static const int maxDimension = 1024;

  /// Builds the input from any supported image. Pure; run it in an isolate.
  static SegmentationInput prepare(Uint8List imageBytes) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(imageBytes);
    } on Object {
      decoded = null;
    }
    if (decoded == null) {
      throw const BackgroundRemovalException('This image could not be read.');
    }
    var image = img.bakeOrientation(decoded);
    final longest = math.max(image.width, image.height);
    if (longest > maxDimension) {
      final factor = maxDimension / longest;
      image = img.copyResize(
        image,
        width: math.max(1, (image.width * factor).round()),
        height: math.max(1, (image.height * factor).round()),
        interpolation: img.Interpolation.average,
      );
    }
    image.exif = img.ExifData();
    // JPEG has no alpha: flatten transparency onto white first.
    final flat = img.Image(width: image.width, height: image.height)
      ..clear(img.ColorRgb8(255, 255, 255));
    img.compositeImage(flat, image);
    return SegmentationInput(Uint8List.fromList(img.encodeJpg(flat, quality: 92)), flat.width, flat.height);
  }
}

/// Removes the background behind the main subject of an image, entirely on
/// device. Pixel work runs in background isolates.
class BackgroundRemovalService {
  BackgroundRemovalService({
    required this.projectRepository,
    this.pixelCutoutProcessor = const PixelCutoutProcessor(),
    SubjectMasker? masker,
    SubjectModelInstaller? modelInstaller,
    Future<Directory> Function()? getTempDir,
  })  : _masker = masker ?? const MlKitSubjectMasker(),
        _modelInstaller = modelInstaller ?? const PlayServicesModelInstaller(),
        _getTempDir = getTempDir ?? getTemporaryDirectory;

  /// Repository for persistent sandbox image storage.
  final ProjectRepository projectRepository;

  /// Worker executing pixel calculations inside a background isolate.
  final PixelCutoutProcessor pixelCutoutProcessor;

  final SubjectMasker _masker;
  final SubjectModelInstaller _modelInstaller;
  final Future<Directory> Function() _getTempDir;

  /// Pixels below this foreground confidence become transparent.
  static const double confidenceThreshold = 0.5;

  /// Returns PNG bytes of [imageBytes] (full size) with everything but the
  /// main subject made transparent. All failures surface as
  /// [BackgroundRemovalException]s with a user-facing message.
  Future<Uint8List> cutOut(Uint8List imageBytes) async {
    try {
      return await _cutOut(imageBytes);
    } on BackgroundRemovalException catch (error) {
      AppLogger.warning('Background removal: $error', tag: 'Segmentation');
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('Background removal failed', tag: 'Segmentation', error: error, stackTrace: stackTrace);
      throw BackgroundRemovalException.failed(error.toString());
    }
  }

  Future<Uint8List> _cutOut(Uint8List imageBytes) async {
    final SubjectModelStatus status;
    try {
      status = await _modelInstaller.ensureModel();
    } on SubjectModelException catch (error) {
      throw BackgroundRemovalException(
        'Google Play services could not provide the background remover. '
        'Make sure Google Play services is up to date and try again.',
        detail: error.detail,
      );
    }
    if (status == SubjectModelStatus.installing) throw BackgroundRemovalException.modelNotReady;

    final input = await Isolate.run(() => SegmentationInput.prepare(imageBytes));
    final temp = File(p.join((await _getTempDir()).path, 'segment_${const Uuid().v4()}.jpg'));
    await temp.writeAsBytes(input.jpegBytes, flush: true);
    final List<double> mask;
    try {
      mask = await _masker.maskFor(temp.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }

    if (mask.length != input.width * input.height) {
      throw BackgroundRemovalException.failed(
        'mask has ${mask.length} values for a ${input.width}x${input.height} image',
      );
    }

    try {
      return await pixelCutoutProcessor.processCutout(
        CutoutProcessingParams(
          imageBytes: imageBytes,
          maskConfidences: mask is Float32List ? mask : Float32List.fromList(mask),
          maskWidth: input.width,
          maskHeight: input.height,
          confidenceThreshold: confidenceThreshold,
        ),
      );
    } on NoSubjectFoundException {
      throw BackgroundRemovalException.noSubject;
    }
  }

  /// Like [cutOut] for an image file.
  Future<Uint8List> cutOutFile(String imagePath) async => cutOut(await File(imagePath).readAsBytes());

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
    modelInstaller: ref.watch(subjectModelInstallerProvider),
  );
}
