import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Immutable state model representing active canvas editing session.
@immutable
class CanvasState {
  const CanvasState({
    required this.project,
    this.selectedLayerId,
    this.isInteracting = false,
  });

  /// The active project model containing canvas specifications and layers.
  final ProjectModel project;

  /// ID of the currently selected/active layer, or null if no layer is focused.
  final String? selectedLayerId;

  /// Whether a gesture, drag, or scale interaction is actively occurring.
  final bool isInteracting;

  /// Returns the currently selected layer entity, if one is active.
  CanvasLayer? get selectedLayer {
    if (selectedLayerId == null) return null;
    for (final layer in project.layers) {
      if (layer.id == selectedLayerId) return layer;
    }
    return null;
  }

  CanvasState copyWith({
    ProjectModel? project,
    String? Function()? selectedLayerId,
    bool? isInteracting,
  }) {
    return CanvasState(
      project: project ?? this.project,
      selectedLayerId: selectedLayerId != null ? selectedLayerId() : this.selectedLayerId,
      isInteracting: isInteracting ?? this.isInteracting,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasState &&
        other.project == project &&
        other.selectedLayerId == selectedLayerId &&
        other.isInteracting == isInteracting;
  }

  @override
  int get hashCode => Object.hash(project, selectedLayerId, isInteracting);

  @override
  String toString() =>
      'CanvasState(projectId: ${project.id}, layers: ${project.layers.length}, '
      'selected: $selectedLayerId, interacting: $isInteracting)';
}

/// Riverpod notifier coordinating canvas workspace layer interactions, mutations,
/// and automated history snapshot recording.
class CanvasNotifier extends FamilyNotifier<CanvasState, ProjectModel> {
  HistoryNotifier get _historyNotifier =>
      ref.read(historyNotifierProvider(arg.id).notifier);

  ProjectRepository get _projectRepository =>
      ref.read(projectRepositoryProvider);

  @override
  CanvasState build(ProjectModel arg) {
    return CanvasState(project: arg);
  }

  /// Updates selection focus to layer [id], or null to deselect.
  void selectLayer(String? id) {
    if (state.selectedLayerId == id) return;
    state = state.copyWith(selectedLayerId: () => id);
  }

  /// Sets whether an active touch/drag interaction is underway.
  void setInteracting(bool isInteracting) {
    if (state.isInteracting == isInteracting) return;
    state = state.copyWith(isInteracting: isInteracting);
  }

  /// Appends [layer] to the canvas, assigning it the top stacking [zIndex],
  /// recording history, and auto-selecting the newly added layer.
  Future<void> addLayer(CanvasLayer layer) async {
    // Record current state before mutating
    await _historyNotifier.pushState(state.project.layers);

    final updatedLayers = List<CanvasLayer>.from(state.project.layers);
    final indexedLayer = _applyZIndex(layer, updatedLayers.length);
    updatedLayers.add(indexedLayer);

    final updatedProject = state.project.copyWith(
      layers: updatedLayers,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      project: updatedProject,
      selectedLayerId: () => indexedLayer.id,
    );

    await _projectRepository.saveProject(updatedProject);
  }

  /// Updates transformation parameters (`x`, `y`, `scale`, `rotation`) for layer with [id].
  Future<void> updateLayerTransform(
    String id, {
    double? x,
    double? y,
    double? scale,
    double? rotation,
    bool recordHistory = true,
  }) async {
    final index = state.project.layers.indexWhere((l) => l.id == id);
    if (index == -1) return;

    if (recordHistory) {
      await _historyNotifier.pushState(state.project.layers);
    }

    final updatedLayers = List<CanvasLayer>.from(state.project.layers);
    updatedLayers[index] = _applyTransform(
      updatedLayers[index],
      x: x,
      y: y,
      scale: scale,
      rotation: rotation,
    );

    final updatedProject = state.project.copyWith(
      layers: updatedLayers,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(project: updatedProject);
    await _projectRepository.saveProject(updatedProject);
  }

  /// Reorders layer from [oldIndex] to [newIndex] and recalculates sequential zIndices.
  Future<void> reorderLayer(int oldIndex, int newIndex) async {
    final layers = state.project.layers;
    if (oldIndex < 0 ||
        oldIndex >= layers.length ||
        newIndex < 0 ||
        newIndex >= layers.length ||
        oldIndex == newIndex) {
      return;
    }

    await _historyNotifier.pushState(layers);

    final updatedList = List<CanvasLayer>.from(layers);
    final movedItem = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, movedItem);

    final reIndexed = _reIndexLayers(updatedList);
    final updatedProject = state.project.copyWith(
      layers: reIndexed,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(project: updatedProject);
    await _projectRepository.saveProject(updatedProject);
  }

  /// Brings layer [id] to the front of the canvas (highest stacking zIndex).
  Future<void> bringToFront(String id) async {
    final index = state.project.layers.indexWhere((l) => l.id == id);
    if (index == -1 || index == state.project.layers.length - 1) return;

    await reorderLayer(index, state.project.layers.length - 1);
  }

  /// Sends layer [id] to the back of the canvas (lowest stacking zIndex).
  Future<void> sendToBack(String id) async {
    final index = state.project.layers.indexWhere((l) => l.id == id);
    if (index == -1 || index == 0) return;

    await reorderLayer(index, 0);
  }

  /// Deletes layer [id], resets selection if deleted, and re-indexes remaining layers.
  Future<void> deleteLayer(String id) async {
    final index = state.project.layers.indexWhere((l) => l.id == id);
    if (index == -1) return;

    await _historyNotifier.pushState(state.project.layers);

    final updatedList = List<CanvasLayer>.from(state.project.layers)..removeAt(index);
    final reIndexed = _reIndexLayers(updatedList);

    final updatedProject = state.project.copyWith(
      layers: reIndexed,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      project: updatedProject,
      selectedLayerId: state.selectedLayerId == id ? () => null : null,
    );

    await _projectRepository.saveProject(updatedProject);
  }

  /// Reverts to the previous state recorded in the [HistoryNotifier].
  Future<void> undo() async {
    final previousLayers = await _historyNotifier.undo(state.project.layers);
    if (previousLayers != null) {
      final updatedProject = state.project.copyWith(
        layers: previousLayers,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        project: updatedProject,
        selectedLayerId: updatedProject.layers.any((l) => l.id == state.selectedLayerId)
            ? () => state.selectedLayerId
            : () => null,
      );

      await _projectRepository.saveProject(updatedProject);
    }
  }

  /// Re-applies the forward state from the [HistoryNotifier].
  Future<void> redo() async {
    final nextLayers = await _historyNotifier.redo(state.project.layers);
    if (nextLayers != null) {
      final updatedProject = state.project.copyWith(
        layers: nextLayers,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        project: updatedProject,
        selectedLayerId: updatedProject.layers.any((l) => l.id == state.selectedLayerId)
            ? () => state.selectedLayerId
            : () => null,
      );

      await _projectRepository.saveProject(updatedProject);
    }
  }

  /// Helper re-assigning sequential zIndex indices (0 to N-1) across layers.
  List<CanvasLayer> _reIndexLayers(List<CanvasLayer> layers) {
    final result = <CanvasLayer>[];
    for (var i = 0; i < layers.length; i++) {
      result.add(_applyZIndex(layers[i], i));
    }
    return result;
  }

  /// Helper applying a specific zIndex to any concrete [CanvasLayer] type.
  CanvasLayer _applyZIndex(CanvasLayer layer, int zIndex) {
    if (layer is ImageLayer) return layer.copyWith(zIndex: zIndex);
    if (layer is TextLayer) return layer.copyWith(zIndex: zIndex);
    if (layer is DoodleLayer) return layer.copyWith(zIndex: zIndex);
    if (layer is StickerLayer) return layer.copyWith(zIndex: zIndex);
    return layer;
  }

  /// Helper applying transformation updates to any concrete [CanvasLayer] type.
  CanvasLayer _applyTransform(
    CanvasLayer layer, {
    double? x,
    double? y,
    double? scale,
    double? rotation,
  }) {
    if (layer is ImageLayer) {
      return layer.copyWith(x: x, y: y, scale: scale, rotation: rotation);
    }
    if (layer is TextLayer) {
      return layer.copyWith(x: x, y: y, scale: scale, rotation: rotation);
    }
    if (layer is DoodleLayer) {
      return layer.copyWith(x: x, y: y, scale: scale, rotation: rotation);
    }
    if (layer is StickerLayer) {
      return layer.copyWith(x: x, y: y, scale: scale, rotation: rotation);
    }
    return layer;
  }
}

/// Family provider exposing [CanvasNotifier] scoped to a [ProjectModel].
final canvasNotifierProvider =
    NotifierProvider.family<CanvasNotifier, CanvasState, ProjectModel>(
  CanvasNotifier.new,
);
