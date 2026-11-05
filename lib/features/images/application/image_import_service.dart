import 'dart:typed_data';
import 'dart:ui';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/images/application/image_normalizer.dart';
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
    required this.originalPath,
  });

  /// Project-relative path of the saved (cropped) image.
  final String relativePath;

  /// Project-relative path of the uncropped original it was cut from.
  final String originalPath;

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

  /// Picks an image from [source], saves its upright, size-limited original
  /// into the sandbox of [projectId], lets the user crop it with preset ratios
  /// and saves the crop as well.
  ///
  /// The original is kept so the crop can be redone or reset later. Returns
  /// `null` (leaving no files behind) when the user cancels picking or cropping.
  /// [onPicked] is called once a photo was chosen, before the slow
  /// conversion starts (e.g. to show a loading indicator).
  Future<ImportedPhoto?> importPhoto({
    required ImageSource source,
    required String projectId,
    void Function()? onPicked,
  }) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return null;
    onPicked?.call();

    final original = await _normalize(await pickedFile.readAsBytes());
    final originalPath = await projectRepository.saveLayerImage(
      projectId,
      original.bytes,
      'orig_${const Uuid().v4()}.${original.extension}',
    );

    final cropped = await recrop(projectId: projectId, originalPath: originalPath);
    if (cropped == null) {
      await projectRepository.deleteFile(originalPath);
    }
    return cropped;
  }

  /// Opens the cropper on the saved original at [originalPath] and saves the
  /// result as a new image in [projectId]. Returns `null` if cancelled.
  Future<ImportedPhoto?> recrop({
    required String projectId,
    required String originalPath,
  }) async {
    final originalFile = await projectRepository.resolveRelativePath(originalPath);
    final croppedFile = await _cropper.cropImage(
      sourcePath: originalFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop',
          toolbarColor: const Color(0xFFFFFFFF),
          toolbarWidgetColor: const Color(0xFF1B1B21),
          statusBarLight: true,
          backgroundColor: const Color(0xFF1B1B21),
          activeControlsWidgetColor: AppTheme.brandSeed,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: defaultAspectRatioPresets,
        ),
        IOSUiSettings(
          title: 'Crop',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
          aspectRatioPresets: defaultAspectRatioPresets,
        ),
      ],
    );
    if (croppedFile == null) return null;

    final normalized = await _normalize(await croppedFile.readAsBytes());
    final relativePath = await projectRepository.saveLayerImage(
      projectId,
      normalized.bytes,
      'img_${const Uuid().v4()}.${normalized.extension}',
    );

    return ImportedPhoto(
      relativePath: relativePath,
      width: normalized.width,
      height: normalized.height,
      originalPath: originalPath,
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
