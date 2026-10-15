Implement the complete Text Layer editing system.

1. In lib/features/layers/presentation/widgets/text_layer_widget.dart:
 - Render TextLayer with its specific attributes: font size, color, font style (italic/bold), shadow (BoxShadow), and optional background box with border radius and padding.

2. In lib/features/layers/application/font_service.dart:
 - Support google_fonts dynamic loading by family name.
 - Implement custom TTF/OTF font loading: provide a method loadFontFromFile(String fontPath, String familyName) using Flutter's FontLoader engine API so users can use imported fonts.

3. Build a bottom sheet modal TextEditSheet:
 - Controls for text input, font family picker, font size slider, color picker (hex/palette), background box toggle with padding and border radius sliders."