import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/fonts/domain/font_catalog.dart';
import 'package:image_editor/features/fonts/domain/font_file_validator.dart';

Uint8List withSignature(List<int> signature) =>
    Uint8List.fromList([...signature, ...List<int>.filled(60, 0)]);

void main() {
  group('curatedFonts', () {
    test('has unique families and covers every script', () {
      final families = curatedFonts.map((f) => f.family).toList();
      expect(families.toSet(), hasLength(families.length));
      for (final script in FontScript.values) {
        expect(curatedFonts.where((f) => f.script == script), isNotEmpty, reason: script.label);
      }
    });

    test('does not list the built-in default font', () {
      expect(curatedFonts.map((f) => f.family), isNot(contains(systemDefaultFontFamily)));
    });
  });

  group('FontFileValidator.detect', () {
    test('recognizes TrueType and OpenType signatures', () {
      expect(FontFileValidator.detect(withSignature([0x00, 0x01, 0x00, 0x00])),
          FontFileFormat.trueType);
      expect(FontFileValidator.detect(withSignature('true'.codeUnits)), FontFileFormat.trueType);
      expect(FontFileValidator.detect(withSignature('OTTO'.codeUnits)), FontFileFormat.openType);
    });

    test('rejects web fonts, collections, other files and tiny input', () {
      expect(FontFileValidator.detect(withSignature('wOFF'.codeUnits)), isNull);
      expect(FontFileValidator.detect(withSignature('wOF2'.codeUnits)), isNull);
      expect(FontFileValidator.detect(withSignature('ttcf'.codeUnits)), isNull);
      expect(FontFileValidator.detect(withSignature([0x89, 0x50, 0x4E, 0x47])), isNull);
      expect(FontFileValidator.detect(Uint8List.fromList([0, 1, 0, 0])), isNull);
    });
  });
}
