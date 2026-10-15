import 'package:flutter/material.dart';

/// Represents an available GPU-accelerated color filter option.
class AppColorFilterItem {
  const AppColorFilterItem({
    required this.id,
    required this.name,
    required this.matrix,
  });

  /// Unique identifier (e.g. 'none', 'grayscale', 'warm', 'cool', 'high_contrast').
  final String id;

  /// Human-readable label for UI display.
  final String name;

  /// 4x5 color transformation matrix (20 double entries).
  final List<double> matrix;

  /// Produces a Flutter [ColorFilter] that executes directly on the GPU.
  ColorFilter get colorFilter => ColorFilter.matrix(matrix);
}

/// Collection of GPU-accelerated 4x5 ColorFilter matrices with zero CPU rendering overhead.
abstract final class AppColorFilters {
  /// Identity matrix (no color alterations).
  static const List<double> identityMatrix = <double>[
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  /// Standard ITU-R BT.709 luminance weights: 0.2126R + 0.7152G + 0.0722B.
  static const List<double> grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0.0, 0.0,
    0.2126, 0.7152, 0.0722, 0.0, 0.0,
    0.2126, 0.7152, 0.0722, 0.0, 0.0,
    0.0,    0.0,    0.0,    1.0, 0.0,
  ];

  /// Warm / Cloudy filter boosting red and amber tones while slightly dampening blues.
  static const List<double> warmMatrix = <double>[
    1.2, 0.0,  0.0,  0.0, 20.0,
    0.0, 1.05, 0.0,  0.0, 10.0,
    0.0, 0.0,  0.85, 0.0, -10.0,
    0.0, 0.0,  0.0,  1.0, 0.0,
  ];

  /// Cool filter with elevated blue/cyan channels and slightly reduced red intensity.
  static const List<double> coolMatrix = <double>[
    0.85, 0.0, 0.0,  0.0, -10.0,
    0.0,  1.0, 0.0,  0.0, 5.0,
    0.0,  0.0, 1.25, 0.0, 20.0,
    0.0,  0.0, 0.0,  1.0, 0.0,
  ];

  /// High contrast stretching matrix emphasizing dark shadows and luminous highlights.
  static const List<double> highContrastMatrix = <double>[
    1.5, 0.0, 0.0, 0.0, -64.0,
    0.0, 1.5, 0.0, 0.0, -64.0,
    0.0, 0.0, 1.5, 0.0, -64.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  /// Predefined list of selectable filters.
  static const List<AppColorFilterItem> availableFilters = <AppColorFilterItem>[
    AppColorFilterItem(
      id: 'none',
      name: 'Normal',
      matrix: identityMatrix,
    ),
    AppColorFilterItem(
      id: 'grayscale',
      name: 'Grayscale',
      matrix: grayscaleMatrix,
    ),
    AppColorFilterItem(
      id: 'warm',
      name: 'Warm',
      matrix: warmMatrix,
    ),
    AppColorFilterItem(
      id: 'cool',
      name: 'Cool',
      matrix: coolMatrix,
    ),
    AppColorFilterItem(
      id: 'high_contrast',
      name: 'High Contrast',
      matrix: highContrastMatrix,
    ),
  ];

  /// Resolves the corresponding [ColorFilter] for the specified [id].
  /// Returns `null` if the filter is 'none', unrecognized, or null.
  static ColorFilter? getFilterByName(String? id) {
    if (id == null || id == 'none') return null;
    for (final item in availableFilters) {
      if (item.id.toLowerCase() == id.toLowerCase()) {
        return item.colorFilter;
      }
    }
    return null;
  }

  /// Resolves the [AppColorFilterItem] for the specified [id], defaulting to 'none'.
  static AppColorFilterItem getFilterItemById(String? id) {
    if (id == null) return availableFilters.first;
    for (final item in availableFilters) {
      if (item.id.toLowerCase() == id.toLowerCase()) {
        return item;
      }
    }
    return availableFilters.first;
  }
}
