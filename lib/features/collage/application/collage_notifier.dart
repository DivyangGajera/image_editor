import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/collage/application/collage_engine.dart';
import 'package:image_editor/features/collage/domain/models/models.dart';

/// State representation for the collage creation setup session.
@immutable
class CollageState {
  const CollageState({
    this.selectedImagePaths = const [],
    this.config = const CollageConfig(),
    this.isCreating = false,
    this.error,
  });

  /// The list of image paths chosen for the collage (must be between 2 and 9).
  final List<String> selectedImagePaths;

  /// Current geometry, border, and layout configuration.
  final CollageConfig config;

  /// Whether project creation and cell generation are executing.
  final bool isCreating;

  /// Error message if generation failed.
  final String? error;

  /// Whether enough images are selected to generate a valid collage.
  bool get canCreate =>
      selectedImagePaths.length >= 2 &&
      selectedImagePaths.length <= 9 &&
      !isCreating;

  CollageState copyWith({
    List<String>? selectedImagePaths,
    CollageConfig? config,
    bool? isCreating,
    String? error,
    bool clearError = false,
  }) {
    return CollageState(
      selectedImagePaths: selectedImagePaths ?? this.selectedImagePaths,
      config: config ?? this.config,
      isCreating: isCreating ?? this.isCreating,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollageState &&
          runtimeType == other.runtimeType &&
          listEquals(selectedImagePaths, other.selectedImagePaths) &&
          config == other.config &&
          isCreating == other.isCreating &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(selectedImagePaths),
        config,
        isCreating,
        error,
      );
}

/// Riverpod notifier managing collage setup, layout selection, and creation.
class CollageNotifier extends Notifier<CollageState> {
  @override
  CollageState build() => const CollageState();

  /// Adds new image paths up to a maximum of 9 total images.
  void addImages(List<String> newPaths) {
    if (newPaths.isEmpty) return;

    final updated = List<String>.from(state.selectedImagePaths);
    for (final path in newPaths) {
      if (!updated.contains(path) && updated.length < 9) {
        updated.add(path);
      }
    }

    state = state.copyWith(
      selectedImagePaths: updated,
      clearError: true,
    );
  }

  /// Removes the image at [index].
  void removeImage(int index) {
    if (index < 0 || index >= state.selectedImagePaths.length) return;

    final updated = List<String>.from(state.selectedImagePaths)..removeAt(index);
    state = state.copyWith(
      selectedImagePaths: updated,
      clearError: true,
    );
  }

  /// Reorders images when dragging thumbnails.
  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.selectedImagePaths.length) return;

    final updated = List<String>.from(state.selectedImagePaths);
    int adjustedNewIndex = newIndex;
    if (adjustedNewIndex > oldIndex) {
      adjustedNewIndex -= 1;
    }
    final item = updated.removeAt(oldIndex);
    updated.insert(adjustedNewIndex, item);

    state = state.copyWith(selectedImagePaths: updated);
  }

  /// Updates the entire collage configuration.
  void updateConfig(CollageConfig config) {
    state = state.copyWith(config: config);
  }

  /// Changes the layout preset (horizontalStrip, verticalStrip, gridMatrix).
  void setLayoutType(CollageLayoutType type) {
    state = state.copyWith(
      config: state.config.copyWith(layoutType: type),
    );
  }

  /// Updates the cell border stroke width in pixels.
  void setBorderWidth(double width) {
    state = state.copyWith(
      config: state.config.copyWith(borderWidth: width),
    );
  }

  /// Updates the border frame color.
  void setBorderColor(int colorValue) {
    state = state.copyWith(
      config: state.config.copyWith(borderColorValue: colorValue),
    );
  }

  /// Updates the outer canvas padding margin in pixels.
  void setOuterMargin(double margin) {
    state = state.copyWith(
      config: state.config.copyWith(outerMargin: margin),
    );
  }

  /// Updates the spacing gap between cells in pixels.
  void setSpacing(double spacing) {
    state = state.copyWith(
      config: state.config.copyWith(spacing: spacing),
    );
  }

  /// Executes background isolate generation and creates the unified [ProjectModel].
  Future<ProjectModel?> createProject({String? title}) async {
    if (!state.canCreate) return null;

    state = state.copyWith(isCreating: true, clearError: true);

    try {
      final engine = ref.read(collageEngineProvider);
      final project = await engine.createCollageProject(
        imagePaths: state.selectedImagePaths,
        config: state.config,
        projectTitle: title,
      );

      state = state.copyWith(isCreating: false);
      return project;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Resets selection and settings back to initial state.
  void reset() {
    state = const CollageState();
  }
}

/// Riverpod provider for [CollageNotifier].
final collageNotifierProvider =
    NotifierProvider<CollageNotifier, CollageState>(CollageNotifier.new);
