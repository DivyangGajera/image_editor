import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand palette, type and Material 3 theme for Chitred: a warm, festive look
/// for Indian small businesses (saffron accent, deep ink, paper ground).
///
/// Widgets should read colors from `Theme.of(context).colorScheme` rather than
/// hard-coding values, so the whole app stays consistent with this theme.
abstract final class AppTheme {
  /// Saffron: highlights and accents.
  static const Color saffron = Color(0xFFF97316);

  /// Deep saffron: primary buttons and selected states (text-safe on white).
  static const Color deepSaffron = Color(0xFFC2410C);

  /// Ink: text and dark editor chrome.
  static const Color ink = Color(0xFF1F1B2E);

  /// Muted ink for secondary text.
  static const Color inkMuted = Color(0xFF4A4458);

  /// Peacock: secondary actions and success.
  static const Color peacock = Color(0xFF0F766E);

  /// Paper: app background.
  static const Color paper = Color(0xFFFFF8F1);

  /// Warm hairline borders.
  static const Color line = Color(0xFFEADFD3);

  /// Primary brand color (used by native screens such as the cropper).
  static const Color brandSeed = deepSaffron;

  /// Neutral backdrop behind the editing canvas, so white canvases stay visible.
  static const Color canvasBackdrop = Color(0xFFF3EEE8);

  /// Destructive action color (delete buttons and handles).
  static const Color danger = Color(0xFFDC2626);

  /// Headings (Poppins, bundled; also covers Devanagari).
  static const String displayFont = 'ChitredDisplay';

  /// Body text, labels and buttons (Inter, bundled).
  static const String textFont = 'ChitredText';

  static const double radiusSmall = 10.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 24.0;

  /// The single light theme used across the app.
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: deepSaffron,
      brightness: Brightness.light,
    ).copyWith(
      primary: deepSaffron,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFEDD5),
      onPrimaryContainer: const Color(0xFF7C2D12),
      secondary: peacock,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFCCFBF1),
      onSecondaryContainer: const Color(0xFF134E4A),
      tertiary: saffron,
      onTertiary: Colors.white,
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFFFFBF7),
      surfaceContainer: const Color(0xFFFBF3EA),
      surfaceContainerHigh: const Color(0xFFF6ECE1),
      surfaceContainerHighest: const Color(0xFFF1E6DA),
      outline: const Color(0xFFB8A99A),
      outlineVariant: line,
      error: danger,
      inverseSurface: ink,
      onInverseSurface: paper,
    );

    final textTheme = _textTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: textFont,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: const Color(0xFFD9CFC4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64.0, 48.0),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64.0, 48.0),
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colorScheme.primaryContainer,
          selectedForegroundColor: colorScheme.onPrimaryContainer,
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        extendedTextStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide(color: colorScheme.outlineVariant),
        labelStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999.0)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colorScheme.primary : null,
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, space: 1.0),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: paper),
        actionTextColor: saffron,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
      ),
    );
  }

  /// Poppins for display, headline and title styles; Inter for the rest.
  static TextTheme _textTheme(ColorScheme colors) {
    // `black` only carries colors; sizes and weights come from `englishLike`.
    // Both are needed, because these styles are also handed straight to
    // component themes (app bar titles, buttons, chips).
    final typography = Typography.material2021(platform: TargetPlatform.android);
    final base = typography.englishLike.merge(typography.black).apply(
          fontFamily: textFont,
          bodyColor: colors.onSurface,
          displayColor: colors.onSurface,
        );
    TextStyle? display(TextStyle? style, FontWeight weight) =>
        style?.copyWith(fontFamily: displayFont, fontWeight: weight, letterSpacing: 0.0);
    return base.copyWith(
      displayLarge: display(base.displayLarge, FontWeight.w700),
      displayMedium: display(base.displayMedium, FontWeight.w700),
      displaySmall: display(base.displaySmall, FontWeight.w700),
      headlineLarge: display(base.headlineLarge, FontWeight.w700),
      headlineMedium: display(base.headlineMedium, FontWeight.w700),
      headlineSmall: display(base.headlineSmall, FontWeight.w600),
      titleLarge: display(base.titleLarge, FontWeight.w600),
      titleMedium: display(base.titleMedium, FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  /// Lists the bundled UI fonts' licenses on the app's licenses page.
  static void registerFontLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final (family, file) in const [('Poppins', 'Poppins-OFL.txt'), ('Inter', 'Inter-OFL.txt')]) {
        yield LicenseEntryWithLineBreaks(<String>[family], await rootBundle.loadString('assets/ui_fonts/$file'));
      }
    });
  }
}
