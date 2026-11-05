import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('headings use the display font and body text the text font', () {
    final theme = AppTheme.light();

    expect(theme.textTheme.headlineSmall!.fontFamily, AppTheme.displayFont);
    expect(theme.textTheme.titleLarge!.fontFamily, AppTheme.displayFont);
    expect(theme.textTheme.bodyMedium!.fontFamily, AppTheme.textFont);
    expect(theme.textTheme.labelLarge!.fontFamily, AppTheme.textFont);
  });

  test('styles handed to components carry real sizes', () {
    final theme = AppTheme.light();

    expect(theme.appBarTheme.titleTextStyle!.fontSize, 22.0);
    expect(theme.textTheme.titleLarge!.fontSize, 22.0);
    expect(theme.textTheme.bodyMedium!.fontSize, 14.0);
    expect(theme.textTheme.labelLarge!.fontSize, 14.0);
    expect(theme.snackBarTheme.contentTextStyle!.fontSize, 14.0);
  });

  test('uses the brand palette', () {
    final colors = AppTheme.light().colorScheme;

    expect(colors.primary, AppTheme.deepSaffron);
    expect(colors.secondary, AppTheme.peacock);
    expect(colors.surface, AppTheme.paper);
    expect(colors.onSurface, AppTheme.ink);
  });

  test('UI font families never reuse a text-layer catalog name', () {
    expect(AppTheme.displayFont, isNot('Poppins'));
    expect(AppTheme.textFont, isNot('Inter'));
  });

  test('the bundled font files and their licenses exist', () {
    for (final file in [
      'Poppins-500.ttf',
      'Poppins-600.ttf',
      'Poppins-700.ttf',
      'Inter-400.ttf',
      'Inter-500.ttf',
      'Inter-600.ttf',
      'Poppins-OFL.txt',
      'Inter-OFL.txt',
    ]) {
      expect(File('assets/ui_fonts/$file').existsSync(), isTrue, reason: file);
    }
  });

  test('font licenses are listed on the licenses page', () async {
    AppTheme.registerFontLicenses();

    final packages = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
    }
    expect(packages, containsAll(<String>['Poppins', 'Inter']));
  });
}
