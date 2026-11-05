import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_saver.g.dart';

/// Thrown when an export cannot be saved to the gallery; [message] is
/// written for the user.
class GallerySaveException implements Exception {
  const GallerySaveException(this.message);
  final String message;

  @override
  String toString() => 'GallerySaveException: $message';
}

/// Saves exported images into the device gallery, in the app's own album.
abstract interface class GallerySaver {
  /// Saves encoded image [bytes] as [name] (without extension).
  Future<void> save(Uint8List bytes, {required String name});

  /// Opens the device's gallery app.
  Future<void> openGallery();
}

/// [GallerySaver] using MediaStore through the `gal` plugin. On Android 9
/// and below it asks for storage permission first; newer versions need none.
class GalGallerySaver implements GallerySaver {
  const GalGallerySaver();

  /// Album the exports are saved into.
  static const String album = AppConstants.appShortName;

  @override
  Future<void> save(Uint8List bytes, {required String name}) async {
    try {
      if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) {
        throw const GallerySaveException(
          'Allow access to photos to save your design to the gallery.',
        );
      }
      await Gal.putImageBytes(bytes, album: album, name: name);
    } on GalException catch (error) {
      throw GallerySaveException(switch (error.type) {
        GalExceptionType.accessDenied =>
          'Allow access to photos to save your design to the gallery.',
        GalExceptionType.notEnoughSpace => 'Not enough storage space to save the image.',
        GalExceptionType.notSupportedFormat => 'This image format cannot be saved.',
        GalExceptionType.unexpected => 'The image could not be saved. Please try again.',
      });
    }
  }

  @override
  Future<void> openGallery() => Gal.open();
}

/// App-wide [GallerySaver]; overridden in tests.
@Riverpod(keepAlive: true)
GallerySaver gallerySaver(Ref ref) => const GalGallerySaver();
