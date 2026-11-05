import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_editor/features/images/application/image_normalizer.dart';
import 'package:image_editor/features/stickers/data/user_sticker_repository.dart';
import 'package:image_editor/features/stickers/domain/models/user_sticker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_stickers_notifier.g.dart';

/// Longest edge of an imported sticker, in pixels. Stickers are small
/// overlays; this keeps them sharp up to 4K exports at typical sizes.
const int maxStickerDimension = 1024;

/// Picks an image file for sticker import; returns its bytes or null.
typedef StickerFileSource = Future<Uint8List?> Function();

/// Normalizes picked image bytes (upright, size-limited, PNG if transparent).
typedef StickerNormalizer = Future<NormalizedImage> Function(Uint8List bytes);

/// Default [StickerFileSource]: the system file picker, limited to images.
Future<Uint8List?> pickStickerFile() async {
  final file = await FilePicker.pickFile(
    dialogTitle: 'Choose a sticker image',
    type: FileType.image,
  );
  return file?.xFile.readAsBytes();
}

/// File source used for sticker import; overridden in tests.
@Riverpod(keepAlive: true)
StickerFileSource stickerFileSource(Ref ref) => pickStickerFile;

/// Normalizer used for sticker import; overridden in tests.
@Riverpod(keepAlive: true)
StickerNormalizer stickerNormalizer(Ref ref) => (bytes) =>
    ImageNormalizer.normalizeInBackground(bytes, maxDimension: maxStickerDimension);

/// Thrown when a picked file cannot be used as a sticker.
class StickerImportException implements Exception {
  const StickerImportException(this.message);
  final String message;

  @override
  String toString() => 'StickerImportException: $message';
}

/// The user's app-wide "My stickers" library, newest first.
@Riverpod(keepAlive: true)
class UserStickersNotifier extends _$UserStickersNotifier {
  // Resolved once per build, so no method touches `ref` after an await.
  late UserStickerRepository _repository;
  late StickerFileSource _pickFile;
  late StickerNormalizer _normalize;

  @override
  Future<List<UserSticker>> build() {
    _repository = ref.watch(userStickerRepositoryProvider);
    _pickFile = ref.watch(stickerFileSourceProvider);
    _normalize = ref.watch(stickerNormalizerProvider);
    return _repository.getAll();
  }

  /// Lets the user pick an image for a new sticker and prepares it (upright,
  /// at most [maxStickerDimension] px). Returns null if cancelled; throws
  /// [StickerImportException] for unreadable images. Save it with [add].
  Future<NormalizedImage?> pickImage() async {
    final bytes = await _pickFile();
    if (bytes == null) return null;
    try {
      return await _normalize(bytes);
    } on FormatException {
      throw const StickerImportException('This file is not a supported image.');
    }
  }

  /// Adds [image], or its background-free [cutoutPng], to the library.
  Future<UserSticker> add(NormalizedImage image, {Uint8List? cutoutPng}) async {
    final sticker = await _repository.save(
      bytes: cutoutPng ?? image.bytes,
      extension: cutoutPng != null ? 'png' : image.extension,
      width: image.width,
      height: image.height,
    );
    if (ref.mounted) {
      state = AsyncData([sticker, ...?state.value]);
    }
    return sticker;
  }

  /// Removes [sticker] from the library; designs already using it keep their copy.
  Future<void> delete(UserSticker sticker) async {
    await _repository.delete(sticker);
    if (ref.mounted) {
      state = AsyncData([
        for (final s in state.value ?? const <UserSticker>[])
          if (s.id != sticker.id) s,
      ]);
    }
  }
}
