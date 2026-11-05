import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_editor/features/export/data/watermark_settings_repository.dart';
import 'package:image_editor/features/export/domain/models/watermark_config.dart';
import 'package:image_editor/features/images/application/image_normalizer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watermark_settings_notifier.g.dart';

/// Longest edge of a stored logo, in pixels.
const int maxLogoDimension = 1024;

/// Picks a logo image; returns its bytes or null if cancelled.
typedef LogoFileSource = Future<Uint8List?> Function();

/// Normalizes picked logo bytes (upright, size-limited, PNG if transparent).
typedef LogoNormalizer = Future<NormalizedImage> Function(Uint8List bytes);

/// Default [LogoFileSource]: the system file picker, limited to images.
Future<Uint8List?> pickLogoFile() async {
  final file = await FilePicker.pickFile(dialogTitle: 'Choose your logo', type: FileType.image);
  return file?.xFile.readAsBytes();
}

/// Logo source used by the watermark settings; overridden in tests.
@Riverpod(keepAlive: true)
LogoFileSource logoFileSource(Ref ref) => pickLogoFile;

/// Logo normalizer used by the watermark settings; overridden in tests.
@Riverpod(keepAlive: true)
LogoNormalizer logoNormalizer(Ref ref) =>
    (bytes) => ImageNormalizer.normalizeInBackground(bytes, maxDimension: maxLogoDimension);

/// Thrown when a picked file cannot be used as a logo.
class LogoImportException implements Exception {
  const LogoImportException(this.message);
  final String message;

  @override
  String toString() => 'LogoImportException: $message';
}

/// The user's remembered brand watermark, set up once and offered on every
/// export.
@Riverpod(keepAlive: true)
class WatermarkSettingsNotifier extends _$WatermarkSettingsNotifier {
  // Resolved once per build, so no method touches `ref` after an await.
  late WatermarkSettingsRepository _repository;
  late LogoFileSource _pickLogo;
  late LogoNormalizer _normalize;

  @override
  Future<WatermarkConfig> build() {
    _repository = ref.watch(watermarkSettingsRepositoryProvider);
    _pickLogo = ref.watch(logoFileSourceProvider);
    _normalize = ref.watch(logoNormalizerProvider);
    return _repository.load();
  }

  /// Saves [config] as the brand watermark. A replaced logo file is deleted.
  Future<void> save(WatermarkConfig config) async {
    final remembered = config.copyWith(isEnabled: false);
    final previousLogo = state.value?.logoRelativePath;

    await _repository.save(remembered);
    if (previousLogo != null && previousLogo != remembered.logoRelativePath) {
      await _repository.deleteFile(previousLogo);
    }
    if (ref.mounted) state = AsyncData(remembered);
  }

  /// Lets the user pick a logo image and stores it. Returns the logo's
  /// app-relative path, or null if cancelled. Call [save] to apply it.
  Future<String?> importLogo() async {
    final bytes = await _pickLogo();
    if (bytes == null) return null;

    final NormalizedImage image;
    try {
      image = await _normalize(bytes);
    } on FormatException {
      throw const LogoImportException('This file is not a supported image.');
    }
    return _repository.saveLogo(image.bytes, image.extension);
  }
}
