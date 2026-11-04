import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/fonts/application/font_resolver.dart';
import 'package:image_editor/features/fonts/domain/font_catalog.dart';

void main() {
  const base = TextStyle(inherit: false, fontSize: 20.0);

  test('applies installed families', () {
    expect(FontResolver.apply(base, 'Anton', {'Anton'}).fontFamily, 'Anton');
    expect(FontResolver.isMissing('Anton', {'Anton'}), isFalse);
  });

  test('falls back to the default font for families that are not installed', () {
    expect(FontResolver.apply(base, 'Anton', {}).fontFamily, isNull);
    expect(FontResolver.isMissing('Anton', {}), isTrue);
  });

  test('the built-in default is never missing and needs no family', () {
    expect(FontResolver.apply(base, systemDefaultFontFamily, {}).fontFamily, isNull);
    expect(FontResolver.isMissing(systemDefaultFontFamily, {}), isFalse);
  });

  test('while the library is loading, families are applied optimistically', () {
    expect(FontResolver.apply(base, 'Anton', null).fontFamily, 'Anton');
    expect(FontResolver.isMissing('Anton', null), isFalse);
  });
}
