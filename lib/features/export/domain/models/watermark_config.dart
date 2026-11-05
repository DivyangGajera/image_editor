import 'package:flutter/foundation.dart';
import 'package:image_editor/core/constants/app_constants.dart';

/// Where the watermark is placed on the exported image.
enum WatermarkPosition {
  bottomRight('Bottom right'),
  bottomLeft('Bottom left'),
  center('Center'),
  tiled('Tiled');

  const WatermarkPosition(this.label);
  final String label;
}

/// What the watermark shows.
enum WatermarkType {
  text('Text'),
  logo('Logo');

  const WatermarkType(this.label);
  final String label;
}

/// The user's brand watermark. It is configured once and remembered; each
/// export then chooses whether to include it ([isEnabled]).
@immutable
class WatermarkConfig {
  const WatermarkConfig({
    this.isEnabled = false,
    this.type = WatermarkType.text,
    this.text = AppConstants.appShortName,
    this.logoRelativePath,
    this.position = WatermarkPosition.bottomRight,
    this.opacity = 0.75,
    this.fontSize = 24.0,
    this.colorValue = 0xFFFFFFFF,
  });

  /// Whether this export includes the watermark. Not persisted: every export
  /// asks again.
  final bool isEnabled;

  final WatermarkType type;

  /// Text shown for [WatermarkType.text].
  final String text;

  /// App-relative path of the logo image for [WatermarkType.logo], e.g.
  /// `branding/logo_<id>.png`. Never an absolute device path.
  final String? logoRelativePath;

  final WatermarkPosition position;

  /// 0..1.
  final double opacity;

  /// Text size in canvas units (relative to a 1080 px canvas).
  final double fontSize;

  /// ARGB text color.
  final int colorValue;

  /// Whether the watermark has something to show.
  bool get isReady => switch (type) {
        WatermarkType.text => text.trim().isNotEmpty,
        WatermarkType.logo => logoRelativePath != null,
      };

  WatermarkConfig copyWith({
    bool? isEnabled,
    WatermarkType? type,
    String? text,
    String? logoRelativePath,
    WatermarkPosition? position,
    double? opacity,
    double? fontSize,
    int? colorValue,
    bool clearLogo = false,
  }) {
    return WatermarkConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      type: type ?? this.type,
      text: text ?? this.text,
      logoRelativePath: clearLogo ? null : (logoRelativePath ?? this.logoRelativePath),
      position: position ?? this.position,
      opacity: opacity ?? this.opacity,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  /// Serializes the remembered settings (everything except [isEnabled]).
  Map<String, Object?> toMap() => <String, Object?>{
        'type': type.name,
        'text': text,
        'logoRelativePath': logoRelativePath,
        'position': position.name,
        'opacity': opacity,
        'fontSize': fontSize,
        'colorValue': colorValue,
      };

  /// Restores settings saved with [toMap]; unknown or missing values fall
  /// back to defaults.
  factory WatermarkConfig.fromMap(Map<dynamic, dynamic> map) {
    const defaults = WatermarkConfig();
    T byName<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;

    return WatermarkConfig(
      type: byName(WatermarkType.values, map['type'], defaults.type),
      text: map['text'] is String ? map['text'] as String : defaults.text,
      logoRelativePath: map['logoRelativePath'] is String ? map['logoRelativePath'] as String : null,
      position: byName(WatermarkPosition.values, map['position'], defaults.position),
      opacity: map['opacity'] is num ? (map['opacity'] as num).toDouble() : defaults.opacity,
      fontSize: map['fontSize'] is num ? (map['fontSize'] as num).toDouble() : defaults.fontSize,
      colorValue: map['colorValue'] is int ? map['colorValue'] as int : defaults.colorValue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatermarkConfig &&
          isEnabled == other.isEnabled &&
          type == other.type &&
          text == other.text &&
          logoRelativePath == other.logoRelativePath &&
          position == other.position &&
          opacity == other.opacity &&
          fontSize == other.fontSize &&
          colorValue == other.colorValue;

  @override
  int get hashCode => Object.hash(
        isEnabled,
        type,
        text,
        logoRelativePath,
        position,
        opacity,
        fontSize,
        colorValue,
      );
}
