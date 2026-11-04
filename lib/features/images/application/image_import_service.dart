import 'dart:ui';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
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

/// Service orchestrating image acquisition from Camera/Gallery,
/// edge-to-edge aspect ratio cropping, and project sandbox persistence.
class ImageImportService {
  ImageImportService({
    ImagePicker? picker,
    ImageCropper? cropper,
    required this.projectRepository,
  })  : _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper();

  final ImagePicker _picker;
  final ImageCropper _cropper;
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

  /// Picks an image from [source], allows the user to crop it with preset ratios,
  /// saves the resulting bytes into the project sandbox, and returns a new [ImageLayer].
  Future<ImageLayer?> pickAndCropImage({
    required ImageSource source,
    required String projectId,
    double defaultX = 0.5,
    double defaultY = 0.5,
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

    final bytes = await croppedFile.readAsBytes();
    final filename = 'img_${const Uuid().v4()}.png';
    final relativePath = await projectRepository.saveLayerImage(projectId, bytes, filename);

    return ImageLayer(
      id: const Uuid().v4(),
      x: defaultX,
      y: defaultY,
      scale: 1.0,
      rotation: 0.0,
      zIndex: 0,
      isVisible: true,
      relativeImagePath: relativePath,
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
