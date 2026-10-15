import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_editor/features/layers/application/font_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('FontService Unit Tests', () {
    late FontService fontService;

    setUp(() {
      fontService = FontService();
    });

    test('availableGoogleFonts contains expected curated typography families', () {
      expect(FontService.availableGoogleFonts, contains('Roboto'));
      expect(FontService.availableGoogleFonts, contains('Inter'));
      expect(FontService.availableGoogleFonts, contains('Montserrat'));
      expect(FontService.availableGoogleFonts, contains('Poppins'));
      expect(FontService.availableGoogleFonts, contains('Playfair Display'));
      expect(FontService.availableGoogleFonts, contains('Orbitron'));
    });

    test('getTextStyle resolves Google font family and preserves baseStyle attributes', () {
      const baseStyle = TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      );

      final style = fontService.getTextStyle(
        fontFamily: 'Roboto',
        baseStyle: baseStyle,
      );

      expect(style.fontSize, 32.0);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.color, Colors.red);
      expect(style.fontFamily, contains('Roboto'));
    });

    test('getTextStyle falls back gracefully to standard TextStyle on unknown font name', () {
      const baseStyle = TextStyle(fontSize: 18.0);
      final style = fontService.getTextStyle(
        fontFamily: 'NonExistentUnknownFontXYZ',
        baseStyle: baseStyle,
      );

      expect(style.fontSize, 18.0);
      expect(style.fontFamily, 'NonExistentUnknownFontXYZ');
    });

    test('loadFontFromFile returns false when file does not exist', () async {
      final result = await fontService.loadFontFromFile(
        '/path/to/non_existent_font.ttf',
        'CustomFontNonExistent',
      );

      expect(result, isFalse);
      expect(fontService.loadedCustomFonts, isEmpty);
    });

    test('loadFontFromFile returns false when file is empty', () async {
      final tempDir = await Directory.systemTemp.createTemp('font_test_');
      final emptyFile = File('${tempDir.path}/empty_font.ttf');
      await emptyFile.writeAsBytes(<int>[]);

      final result = await fontService.loadFontFromFile(
        emptyFile.path,
        'EmptyCustomFont',
      );

      expect(result, isFalse);
      expect(fontService.loadedCustomFonts.contains('EmptyCustomFont'), isFalse);

      await tempDir.delete(recursive: true);
    });

    test('fontServiceProvider provides FontService singleton in Riverpod container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(fontServiceProvider);
      expect(service, isA<FontService>());
      expect(service.loadedCustomFonts, isEmpty);
    });
  });
}
