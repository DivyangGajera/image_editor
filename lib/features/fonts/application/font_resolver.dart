import 'package:flutter/painting.dart';
import 'package:image_editor/features/fonts/domain/font_catalog.dart';

/// Applies a text layer's font family using the font library, shared by the
/// canvas and the export so both render identically.
abstract final class FontResolver {
  /// [base] with [family] applied if it can be rendered; otherwise [base]
  /// unchanged, which renders in the built-in default font.
  ///
  /// [installed] is null while the library is still loading, in which case
  /// the family is applied optimistically.
  static TextStyle apply(TextStyle base, String family, Set<String>? installed) {
    if (family == systemDefaultFontFamily) return base;
    if (installed != null && !installed.contains(family)) return base;
    return base.copyWith(fontFamily: family);
  }

  /// Whether [family] is neither built in nor installed, e.g. after the user
  /// deleted it. Text then falls back to the default font.
  static bool isMissing(String family, Set<String>? installed) {
    return installed != null &&
        family != systemDefaultFontFamily &&
        !installed.contains(family);
  }
}
