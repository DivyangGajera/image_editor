import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor_ui_notifier.g.dart';

/// What a touch on the canvas does.
enum EditorMode {
  /// Tap selects layers; drag, pinch and rotate transform them.
  select,

  /// Touches draw freehand strokes that become doodle layers.
  draw,
}

/// Ephemeral editor UI state (not persisted, not part of undo history).
@immutable
class EditorUiState {
  const EditorUiState({
    this.mode = EditorMode.select,
    this.drawColorValue = defaultDrawColor,
    this.drawStrokeWidth = defaultStrokeWidth,
    this.drawGlow = false,
    this.isFilterStripOpen = false,
  });

  static const int defaultDrawColor = 0xFFEF4444;
  static const double defaultStrokeWidth = 8.0;
  static const double minStrokeWidth = 2.0;
  static const double maxStrokeWidth = 40.0;

  final EditorMode mode;

  /// Brush color (ARGB) for new strokes.
  final int drawColorValue;

  /// Brush width in canvas units for new strokes.
  final double drawStrokeWidth;

  /// Whether new strokes get the neon glow effect.
  final bool drawGlow;

  /// Whether the filter strip is shown for the selected image.
  final bool isFilterStripOpen;

  EditorUiState copyWith({
    EditorMode? mode,
    int? drawColorValue,
    double? drawStrokeWidth,
    bool? drawGlow,
    bool? isFilterStripOpen,
  }) {
    return EditorUiState(
      mode: mode ?? this.mode,
      drawColorValue: drawColorValue ?? this.drawColorValue,
      drawStrokeWidth: drawStrokeWidth ?? this.drawStrokeWidth,
      drawGlow: drawGlow ?? this.drawGlow,
      isFilterStripOpen: isFilterStripOpen ?? this.isFilterStripOpen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorUiState &&
          other.mode == mode &&
          other.drawColorValue == drawColorValue &&
          other.drawStrokeWidth == drawStrokeWidth &&
          other.drawGlow == drawGlow &&
          other.isFilterStripOpen == isFilterStripOpen;

  @override
  int get hashCode =>
      Object.hash(mode, drawColorValue, drawStrokeWidth, drawGlow, isFilterStripOpen);
}

/// Editor UI state for one open project; reset when the editor closes.
@riverpod
class EditorUiNotifier extends _$EditorUiNotifier {
  @override
  EditorUiState build(String projectId) => const EditorUiState();

  void enterDrawMode() {
    state = state.copyWith(mode: EditorMode.draw, isFilterStripOpen: false);
  }

  void exitDrawMode() {
    state = state.copyWith(mode: EditorMode.select);
  }

  void setDrawColor(int colorValue) {
    state = state.copyWith(drawColorValue: colorValue);
  }

  void setDrawStrokeWidth(double width) {
    state = state.copyWith(
      drawStrokeWidth: width.clamp(
        EditorUiState.minStrokeWidth,
        EditorUiState.maxStrokeWidth,
      ),
    );
  }

  void toggleDrawGlow() {
    state = state.copyWith(drawGlow: !state.drawGlow);
  }

  void toggleFilterStrip() {
    state = state.copyWith(isFilterStripOpen: !state.isFilterStripOpen);
  }

  void closeFilterStrip() {
    if (state.isFilterStripOpen) {
      state = state.copyWith(isFilterStripOpen: false);
    }
  }
}
