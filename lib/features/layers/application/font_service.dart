import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Service responsible for typography styling, resolving Google Fonts dynamically,
/// and registering custom user-imported TTF/OTF fonts in the Flutter engine via [FontLoader].
class FontService {
  FontService();

  /// Curated catalogue of popular Google Font families available in the editor.
  static const List<String> availableGoogleFonts = <String>[
    'Roboto',
    'Inter',
    'Montserrat',
    'Poppins',
    'Playfair Display',
    'Oswald',
    'Dancing Script',
    'Pacifico',
    'Bebas Neue',
    'Lobster',
    'Caveat',
    'Orbitron',
  ];

  final Set<String> _loadedCustomFonts = <String>{};

  /// Set of custom font family names currently registered with the engine.
  Set<String> get loadedCustomFonts => Set<String>.unmodifiable(_loadedCustomFonts);

  /// Resolves a [TextStyle] for the specified [fontFamily], querying Google Fonts
  /// when available, falling back to local/system font families gracefully.
  TextStyle getTextStyle({
    required String fontFamily,
    TextStyle? baseStyle,
  }) {
    if (_loadedCustomFonts.contains(fontFamily)) {
      return (baseStyle ?? const TextStyle()).copyWith(fontFamily: fontFamily);
    }

    if (!GoogleFonts.config.allowRuntimeFetching) {
      return (baseStyle ?? const TextStyle()).copyWith(fontFamily: fontFamily);
    }

    try {
      return GoogleFonts.getFont(fontFamily, textStyle: baseStyle);
    } catch (_) {
      // Fallback to system font if network/GoogleFonts lookup fails or offline
      return (baseStyle ?? const TextStyle()).copyWith(fontFamily: fontFamily);
    }
  }

  /// Loads and registers a custom TTF or OTF font file from [fontPath] under [familyName]
  /// into the Flutter rendering engine using [FontLoader].
  Future<bool> loadFontFromFile(String fontPath, String familyName) async {
    if (_loadedCustomFonts.contains(familyName)) {
      return true;
    }

    try {
      final file = File(fontPath);
      if (!await file.exists()) {
        return false;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return false;
      }

      final fontLoader = FontLoader(familyName);
      fontLoader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
      await fontLoader.load();

      _loadedCustomFonts.add(familyName);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Riverpod provider for singleton instance of [FontService].
final fontServiceProvider = Provider<FontService>((ref) {
  return FontService();
});
