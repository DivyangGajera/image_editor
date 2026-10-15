import 'package:hive_ce/hive.dart';
import 'canvas_layer.dart';

part 'text_layer.g.dart';

/// Represents a styled typography layer positioned on the canvas.
@HiveType(typeId: 1)
class TextLayer extends CanvasLayer {
  const TextLayer({
    required super.id,
    required super.x,
    required super.y,
    super.scale = 1.0,
    super.rotation = 0.0,
    super.zIndex = 0,
    super.isVisible = true,
    required this.text,
    this.fontFamily = 'Roboto',
    this.isCustomFont = false,
    this.customFontPath,
    this.textColorValue = 0xFFFFFFFF,
    this.fontSize = 24.0,
    this.isBold = false,
    this.isItalic = false,
    this.boxColorValue,
    this.boxBorderRadius = 0.0,
    this.shadowColorValue,
  });

  /// The text content to display.
  @HiveField(7)
  final String text;

  /// Font family name (e.g. 'Roboto', 'Inter', or custom font name).
  @HiveField(8)
  final String fontFamily;

  /// Whether this layer uses a user-imported custom font file.
  @HiveField(9)
  final bool isCustomFont;

  /// Project-relative path to the custom font file if [isCustomFont] is true.
  @HiveField(10)
  final String? customFontPath;

  /// 32-bit ARGB color value for the text foreground.
  @HiveField(11)
  final int textColorValue;

  /// Base font size in canvas units.
  @HiveField(12)
  final double fontSize;

  /// Whether bold font weight is applied.
  @HiveField(13)
  final bool isBold;

  /// Whether italic font style is applied.
  @HiveField(14)
  final bool isItalic;

  /// 32-bit ARGB color value for the background pill/box, if enabled.
  @HiveField(15)
  final int? boxColorValue;

  /// Border corner radius for the background box.
  @HiveField(16)
  final double boxBorderRadius;

  /// 32-bit ARGB color value for text drop shadow, if enabled.
  @HiveField(17)
  final int? shadowColorValue;

  @override
  TextLayer copyWith({
    String? id,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
    bool? isVisible,
    String? text,
    String? fontFamily,
    bool? isCustomFont,
    String? customFontPath,
    int? textColorValue,
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    int? boxColorValue,
    double? boxBorderRadius,
    int? shadowColorValue,
  }) {
    return TextLayer(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      isVisible: isVisible ?? this.isVisible,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      isCustomFont: isCustomFont ?? this.isCustomFont,
      customFontPath: customFontPath ?? this.customFontPath,
      textColorValue: textColorValue ?? this.textColorValue,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      boxColorValue: boxColorValue ?? this.boxColorValue,
      boxBorderRadius: boxBorderRadius ?? this.boxBorderRadius,
      shadowColorValue: shadowColorValue ?? this.shadowColorValue,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextLayer &&
        other.id == id &&
        other.x == x &&
        other.y == y &&
        other.scale == scale &&
        other.rotation == rotation &&
        other.zIndex == zIndex &&
        other.isVisible == isVisible &&
        other.text == text &&
        other.fontFamily == fontFamily &&
        other.isCustomFont == isCustomFont &&
        other.customFontPath == customFontPath &&
        other.textColorValue == textColorValue &&
        other.fontSize == fontSize &&
        other.isBold == isBold &&
        other.isItalic == isItalic &&
        other.boxColorValue == boxColorValue &&
        other.boxBorderRadius == boxBorderRadius &&
        other.shadowColorValue == shadowColorValue;
  }

  @override
  int get hashCode => Object.hash(
        id,
        x,
        y,
        scale,
        rotation,
        zIndex,
        isVisible,
        text,
        fontFamily,
        isCustomFont,
        customFontPath,
        textColorValue,
        fontSize,
        isBold,
        isItalic,
        boxColorValue,
        boxBorderRadius,
        shadowColorValue,
      );

  @override
  String toString() =>
      'TextLayer(id: $id, text: $text, fontFamily: $fontFamily, fontSize: $fontSize, '
      'textColorValue: $textColorValue, isBold: $isBold, isItalic: $isItalic, '
      'boxColorValue: $boxColorValue, boxBorderRadius: $boxBorderRadius, '
      'shadowColorValue: $shadowColorValue, x: $x, y: $y, scale: $scale, '
      'rotation: $rotation, zIndex: $zIndex, isVisible: $isVisible)';
}
