import 'dart:typed_data';

/// Font container formats the app can load.
enum FontFileFormat {
  trueType('ttf'),
  openType('otf');

  const FontFileFormat(this.extension);

  /// File extension used when saving, without the dot.
  final String extension;
}

/// Identifies font files by their signature (first four bytes) rather than
/// the file name, so renamed or oddly-typed files are judged by content.
abstract final class FontFileValidator {
  /// Returns the format of [bytes], or null if they are not a single
  /// TrueType/OpenType font (collections and web fonts are not supported).
  static FontFileFormat? detect(Uint8List bytes) {
    if (bytes.length < 12) return null;
    final signature = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    return switch (signature) {
      0x00010000 => FontFileFormat.trueType, // TrueType outlines
      0x74727565 => FontFileFormat.trueType, // 'true' (legacy Apple TrueType)
      0x4F54544F => FontFileFormat.openType, // 'OTTO' (CFF outlines)
      _ => null,
    };
  }
}
