import 'package:flutter/foundation.dart';

/// Visual style group of a catalog font.
enum FontCategory {
  sans('Sans'),
  serif('Serif'),
  display('Display'),
  handwriting('Handwriting');

  const FontCategory(this.label);
  final String label;
}

/// Writing system a catalog font is chosen for.
enum FontScript {
  latin('English'),
  devanagari('Hindi'),
  gujarati('Gujarati');

  const FontScript(this.label);
  final String label;
}

/// A downloadable font in the curated catalog. Only names ship with the app;
/// files are downloaded on demand.
@immutable
class CatalogFont {
  const CatalogFont(this.family, this.category, this.script);

  /// Google Fonts family name, also used as the registered family.
  final String family;
  final FontCategory category;
  final FontScript script;
}

/// Name of the built-in font. Text layers using it render with the platform
/// default (Roboto on Android) and need no download.
const String systemDefaultFontFamily = 'Roboto';

/// Curated Google Fonts families suited to photo edits and promotional
/// graphics. Every entry was verified to resolve to a single Regular TrueType
/// file through the Google Fonts CSS API.
const List<CatalogFont> curatedFonts = <CatalogFont>[
  // English: sans serif
  CatalogFont('Montserrat', FontCategory.sans, FontScript.latin),
  CatalogFont('Poppins', FontCategory.sans, FontScript.latin),
  CatalogFont('Inter', FontCategory.sans, FontScript.latin),
  CatalogFont('Lato', FontCategory.sans, FontScript.latin),
  CatalogFont('Open Sans', FontCategory.sans, FontScript.latin),
  CatalogFont('Raleway', FontCategory.sans, FontScript.latin),
  CatalogFont('Nunito', FontCategory.sans, FontScript.latin),
  CatalogFont('Work Sans', FontCategory.sans, FontScript.latin),
  CatalogFont('Rubik', FontCategory.sans, FontScript.latin),
  CatalogFont('Archivo Black', FontCategory.sans, FontScript.latin),
  CatalogFont('Barlow Condensed', FontCategory.sans, FontScript.latin),
  // English: serif
  CatalogFont('Playfair Display', FontCategory.serif, FontScript.latin),
  CatalogFont('Merriweather', FontCategory.serif, FontScript.latin),
  CatalogFont('Lora', FontCategory.serif, FontScript.latin),
  CatalogFont('Roboto Slab', FontCategory.serif, FontScript.latin),
  CatalogFont('DM Serif Display', FontCategory.serif, FontScript.latin),
  CatalogFont('Abril Fatface', FontCategory.serif, FontScript.latin),
  CatalogFont('Cormorant Garamond', FontCategory.serif, FontScript.latin),
  // English: display
  CatalogFont('Bebas Neue', FontCategory.display, FontScript.latin),
  CatalogFont('Oswald', FontCategory.display, FontScript.latin),
  CatalogFont('Anton', FontCategory.display, FontScript.latin),
  CatalogFont('Bungee', FontCategory.display, FontScript.latin),
  CatalogFont('Righteous', FontCategory.display, FontScript.latin),
  CatalogFont('Alfa Slab One', FontCategory.display, FontScript.latin),
  CatalogFont('Fredoka', FontCategory.display, FontScript.latin),
  CatalogFont('Bangers', FontCategory.display, FontScript.latin),
  CatalogFont('Black Ops One', FontCategory.display, FontScript.latin),
  // English: handwriting
  CatalogFont('Pacifico', FontCategory.handwriting, FontScript.latin),
  CatalogFont('Lobster', FontCategory.handwriting, FontScript.latin),
  CatalogFont('Dancing Script', FontCategory.handwriting, FontScript.latin),
  CatalogFont('Great Vibes', FontCategory.handwriting, FontScript.latin),
  CatalogFont('Satisfy', FontCategory.handwriting, FontScript.latin),
  CatalogFont('Caveat', FontCategory.handwriting, FontScript.latin),
  CatalogFont('Kaushan Script', FontCategory.handwriting, FontScript.latin),
  CatalogFont('Permanent Marker', FontCategory.handwriting, FontScript.latin),
  CatalogFont('Sacramento', FontCategory.handwriting, FontScript.latin),
  // Hindi (Devanagari)
  CatalogFont('Hind', FontCategory.sans, FontScript.devanagari),
  CatalogFont('Mukta', FontCategory.sans, FontScript.devanagari),
  CatalogFont('Noto Sans Devanagari', FontCategory.sans, FontScript.devanagari),
  CatalogFont('Baloo 2', FontCategory.display, FontScript.devanagari),
  CatalogFont('Teko', FontCategory.display, FontScript.devanagari),
  CatalogFont('Rozha One', FontCategory.serif, FontScript.devanagari),
  CatalogFont('Martel', FontCategory.serif, FontScript.devanagari),
  CatalogFont('Laila', FontCategory.serif, FontScript.devanagari),
  CatalogFont('Yatra One', FontCategory.display, FontScript.devanagari),
  CatalogFont('Kalam', FontCategory.handwriting, FontScript.devanagari),
  // Gujarati
  CatalogFont('Hind Vadodara', FontCategory.sans, FontScript.gujarati),
  CatalogFont('Mukta Vaani', FontCategory.sans, FontScript.gujarati),
  CatalogFont('Noto Sans Gujarati', FontCategory.sans, FontScript.gujarati),
  CatalogFont('Baloo Bhai 2', FontCategory.display, FontScript.gujarati),
  CatalogFont('Shrikhand', FontCategory.display, FontScript.gujarati),
  CatalogFont('Kumar One', FontCategory.display, FontScript.gujarati),
  CatalogFont('Mogra', FontCategory.display, FontScript.gujarati),
  CatalogFont('Rasa', FontCategory.serif, FontScript.gujarati),
  CatalogFont('Farsan', FontCategory.handwriting, FontScript.gujarati),
];
