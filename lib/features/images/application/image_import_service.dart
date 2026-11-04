import 'dart:typed_data';
import 'dart:ui';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/images/application/image_normalizer.dart';
import 'package:image_editor/features/layers/application/layer_placement.dart';
import 'package:image_editor/features/layers/domain/models/image_layer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'image_import_service.g.dart';

/// 4:5 aspect ratio preset for Instagram Feed Posts.
class CropAspectRatioPreset4x5 implements CropAspectRatioPresetData {
  const CropAspectRatioPreset4x5();

  @override
  (int, int)? get data => (4, 5);

  @override
  String get name => '4:5';
}

/// 9:16 aspect ratio preset for Stories and Reels.
class CropAspectRatioPreset9x16 implements CropAspectRatioPresetData {
  const CropAspectRatioPreset9x16();

  @override
  (int, int)? get data => (9, 16);

  @override
  String get name => '9:16';
}

/// A photo saved into a project sandbox by [ImageImportService.importPhoto].
class ImportedPhoto {
  const ImportedPhoto({
    required this.relativePath,
    required this.width,
    required this.height,
  });

  /// Project-relative path of the saved image.
  final String relativePath;

  /// Pixel size after normalization.
  final int width;
  final int height;

  Size get size => Size(width.toDouble(), height.toDouble());
}

/// Service orchestrating image acquisition from Camera/Gallery,
/// edge-to-edge aspect ratio cropping, and project sandbox persistence.
class ImageImportService {
  ImageImportService({
    ImagePicker? picker,
    ImageCropper? cropper,
    Future<NormalizedImage> Function(Uint8List bytes)? normalizer,
    required this.projectRepository,
  })  : _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper(),
        _normalize = normalizer ?? ImageNormalizer.normalizeInBackground;

  final ImagePicker _picker;
  final ImageCropper _cropper;
  final Future<NormalizedImage> Function(Uint8List bytes) _normalize;
  final ProjectRepository projectRepository;

  /// Preset aspect ratios supported by the cropping workflow:
  /// Free crop (Original), 1:1 (Square), 4:5 (Post), 9:16 (Story/Reel), 16:9 (Landscape).
  static const List<CropAspectRatioPresetData> defaultAspectRatioPresets = [
    CropAspectRatioPreset.original,
    CropAspectRatioPreset.square,
    CropAspectRatioPreset4x5(),
    CropAspectRatioPreset9x16(),
    CropAspectRatioPreset.ratio16x9,
  ];

  /// Picks an image from [source], lets the user crop it with preset ratios,
  /// normalizes it off the UI isolate (upright, at most
  /// [ImageNormalizer.maxDimension] px) and saves it into the sandbox of
  /// [projectId].
  ///
  /// Returns `null` when the user cancels picking or cropping.
  Future<ImportedPhoto?> importPhoto({
    required ImageSource source,
    required String projectId,
  }) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return null;

    final croppedFile = await _cropper.cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color(0xFF161622),
          toolbarWidgetColor: const Color(0xFFFFFFFF),
          backgroundColor: const Color(0xFF161622),
          activeControlsWidgetColor: const Color(0xFF4E95FF),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: defaultAspectRatioPresets,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          aspectRatioPresets: defaultAspectRatioPresets,
        ),
      ],
    );

    if (croppedFile == null) return null;

    final normalized = await _normalize(await croppedFile.readAsBytes());
    final filename = 'img_${const Uuid().v4()}.${normalized.extension}';
    final relativePath = await projectRepository.saveLayerImage(
      projectId,
      normalized.bytes,
      filename,
    );

    return ImportedPhoto(
      relativePath: relativePath,
      width: normalized.width,
      height: normalized.height,
    );
  }

  /// Imports a photo (see [importPhoto]) and returns a new [ImageLayer]
  /// scaled to fit [canvasSize]. Returns `null` when the user cancels.
  Future<ImageLayer?> pickAndCropImage({
    required ImageSource source,
    required String projectId,
    required Size canvasSize,
    double defaultX = 0.5,
    double defaultY = 0.5,
  }) async {
    final photo = await importPhoto(source: source, projectId: projectId);
    if (photo == null) return null;

    return ImageLayer(
      id: const Uuid().v4(),
      x: defaultX,
      y: defaultY,
      scale: LayerPlacement.fitScale(contentSize: photo.size, canvasSize: canvasSize),
      relativeImagePath: photo.relativePath,
    );
  }
}

/// App-wide singleton [ImageImportService].
@Riverpod(keepAlive: true)
ImageImportService imageImportService(Ref ref) {
  return ImageImportService(
    projectRepository: ref.watch(projectRepositoryProvider),
  );
}
