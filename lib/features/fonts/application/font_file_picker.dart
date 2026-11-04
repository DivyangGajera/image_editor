import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_file_picker.g.dart';

/// A file chosen by the user for font import.
class PickedFontFile {
  const PickedFontFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

/// Opens the system document picker for a font file.
///
/// Any file type is allowed on purpose: many Android file managers label
/// fonts as `application/octet-stream`, which an extension filter would hide.
/// The library validates the content instead.
class FontFilePicker {
  const FontFilePicker();

  /// Returns the chosen file, or null if the user cancelled.
  Future<PickedFontFile?> pick() async {
    final file = await FilePicker.pickFile(dialogTitle: 'Choose a font file (.ttf or .otf)');
    if (file == null) return null;
    return PickedFontFile(name: file.name, bytes: await file.xFile.readAsBytes());
  }
}

/// App-wide [FontFilePicker]; overridden in tests.
@Riverpod(keepAlive: true)
FontFilePicker fontFilePicker(Ref ref) => const FontFilePicker();
