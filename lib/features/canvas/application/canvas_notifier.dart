import 'package:flutter/foundation.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'canvas_notifier.g.dart';

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
/// and automated history snapshot recording for a single project.
///
/// Keyed by project ID. The project is loaded from [ProjectRepository] on first
/// use; every mutation records undo history and persists the project.
@riverpod
class CanvasNotifier extends _$CanvasNotifier {
  HistoryNotifier get _historyNotifier =>
      ref.read(historyProvider(projectId).notifier);

  ProjectRepository get _projectRepository =>
      ref.read(projectRepositoryProvider);

  /// The loaded canvas state. Mutations are only valid once loading completed.
  CanvasState get _current => state.requireValue;

  set _current(CanvasState value) => state = AsyncData<CanvasState>(value);

  /// Layers captured when the current gesture began; null when idle.
  List<CanvasLayer>? _interactionSnapshot;

  @override
  Future<CanvasState> build(String projectId) async {
    final project = await ref.read(projectRepositoryProvider).loadProject(projectId);
    if (project == null) {
      throw StateError('Project "$projectId" was not found.');
    }

    // Keep this project's history alive for as long as the canvas is in use,
    // without rebuilding the canvas whenever the history metrics change.
    // Subscribed only once the project exists, so no orphan history is created.
    ref.listen(historyProvider(projectId), (_, _) {});

    return CanvasState(project: project);
  }

  /// Updates selection focus to layer [id], or null to deselect.
  void selectLayer(String? id) {
    if (_current.selectedLayerId == id) return;
    _current = _current.copyWith(selectedLayerId: () => id);
  }

  /// Starts a continuous gesture (drag, pinch, rotate) on layer [id].
  ///
  /// Selects the layer and remembers the pre-gesture layers, so the whole
  /// gesture becomes exactly one undo step when [commitInteraction] is called.
  void beginInteraction(String id) {
    _interactionSnapshot ??= _current.project.layers;
    _current = _current.copyWith(
      selectedLayerId: () => id,
      isInteracting: true,
    );
  }

  /// Applies a live transform to layer [id] while a gesture is in progress.
  ///
  /// Updates state only: no history entry and no disk write per frame.
  void previewTransform(
    String id, {
    double? x,
    double? y,
    double? scale,
    double? rotation,
  }) {
    final index = _current.project.layers.indexWhere((l) => l.id == id);
    if (index == -1) return;

    final updatedLayers = List<CanvasLayer>.from(_current.project.layers);
    updatedLayers[index] = updatedLayers[index].copyWith(
      x: x,
      y: y,
      scale: scale,
      rotation: rotation,
    );
    _current = _current.copyWith(
      project: _current.project.copyWith(layers: updatedLayers),
    );
  }

  /// Ends the current gesture: records a single undo step with the
  /// pre-gesture layers and persists the project once, if anything changed.
  Future<void> commitInteraction() async {
    final snapshot = _interactionSnapshot;
    _interactionSnapshot = null;
    _current = _current.copyWith(isInteracting: false);

    if (snapshot == null || listEquals(snapshot, _current.project.layers)) {
      return;
    }

    await _historyNotifier.pushState(snapshot);
    final updatedProject = _current.project.copyWith(updatedAt: DateTime.now());
    _current = _current.copyWith(project: updatedProject);
    await _projectRepository.saveProject(updatedProject);
  }

  /// Appends [layer] on top of the canvas, assigning it the top stacking
  /// zIndex, recording history and persisting. The new layer is selected
  /// unless [select] is false (e.g. strokes added while drawing).
  Future<void> addLayer(CanvasLayer layer, {bool select = true}) async {
    // Record current state before mutating
    await _historyNotifier.pushState(_current.project.layers);

    final updatedLayers = List<CanvasLayer>.from(_current.project.layers);
    final indexedLayer = layer.copyWith(zIndex: updatedLayers.length);
    updatedLayers.add(indexedLayer);

    final updatedProject = _current.project.copyWith(
      layers: updatedLayers,
      updatedAt: DateTime.now(),
    );

    _current = _current.copyWith(
      project: updatedProject,
      selectedLayerId: select ? () => indexedLayer.id : null,
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
  }) async {
    final index = _current.project.layers.indexWhere((l) => l.id == id);
    if (index == -1) return;

    await _historyNotifier.pushState(_current.project.layers);

    final updatedLayers = List<CanvasLayer>.from(_current.project.layers);
    updatedLayers[index] = updatedLayers[index].copyWith(
      x: x,
      y: y,
      scale: scale,
      rotation: rotation,
    );

    final updatedProject = _current.project.copyWith(
      layers: updatedLayers,
      updatedAt: DateTime.now(),
    );

    _current = _current.copyWith(project: updatedProject);
    await _projectRepository.saveProject(updatedProject);
  }

  /// Replaces an existing layer with [layer], records history, and persists updates.
  Future<void> updateLayer(CanvasLayer layer) async {
    final index = _current.project.layers.indexWhere((l) => l.id == layer.id);
    if (index == -1) return;

    await _historyNotifier.pushState(_current.project.layers);

    final updatedLayers = List<CanvasLayer>.from(_current.project.layers);
    updatedLayers[index] = layer;

    final updatedProject = _current.project.copyWith(
      layers: updatedLayers,
      updatedAt: DateTime.now(),
    );

    _current = _current.copyWith(project: updatedProject);
    await _projectRepository.saveProject(updatedProject);
  }

  /// Reorders layer from [oldIndex] to [newIndex] and recalculates sequential zIndices.
  Future<void> reorderLayer(int oldIndex, int newIndex) async {
    final layers = _current.project.layers;
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
    final updatedProject = _current.project.copyWith(
      layers: reIndexed,
      updatedAt: DateTime.now(),
    );

    _current = _current.copyWith(project: updatedProject);
    await _projectRepository.saveProject(updatedProject);
  }

  /// Brings layer [id] to the front of the canvas (highest stacking zIndex).
  Future<void> bringToFront(String id) async {
    final index = _current.project.layers.indexWhere((l) => l.id == id);
    if (index == -1 || index == _current.project.layers.length - 1) return;

    await reorderLayer(index, _current.project.layers.length - 1);
  }

  /// Sends layer [id] to the back of the canvas (lowest stacking zIndex).
  Future<void> sendToBack(String id) async {
    final index = _current.project.layers.indexWhere((l) => l.id == id);
    if (index == -1 || index == 0) return;

    await reorderLayer(index, 0);
  }

  /// Deletes layer [id], resets selection if deleted, and re-indexes remaining layers.
  Future<void> deleteLayer(String id) async {
    final index = _current.project.layers.indexWhere((l) => l.id == id);
    if (index == -1) return;

    await _historyNotifier.pushState(_current.project.layers);

    final updatedList = List<CanvasLayer>.from(_current.project.layers)..removeAt(index);
    final reIndexed = _reIndexLayers(updatedList);

    final updatedProject = _current.project.copyWith(
      layers: reIndexed,
      updatedAt: DateTime.now(),
    );

    _current = _current.copyWith(
      project: updatedProject,
      selectedLayerId: _current.selectedLayerId == id ? () => null : null,
    );

    await _projectRepository.saveProject(updatedProject);
  }

  /// Normalized offset applied to a duplicate so it does not hide the original.
  static const double duplicateOffset = 0.03;

  /// Duplicates layer [id] directly above the original, slightly offset,
  /// selects the copy, records history and persists. Returns the copy's ID.
  Future<String?> duplicateLayer(String id) async {
    final layers = _current.project.layers;
    final index = layers.indexWhere((l) => l.id == id);
    if (index == -1) return null;

    await _historyNotifier.pushState(layers);

    final original = layers[index];
    final copy = original.copyWith(
      id: const Uuid().v4(),
      x: (original.x + duplicateOffset).clamp(-0.5, 1.5),
      y: (original.y + duplicateOffset).clamp(-0.5, 1.5),
    );
    final updatedList = List<CanvasLayer>.from(layers)..insert(index + 1, copy);
    final updatedProject = _current.project.copyWith(
      layers: _reIndexLayers(updatedList),
      updatedAt: DateTime.now(),
    );

    _current = _current.copyWith(
      project: updatedProject,
      selectedLayerId: () => copy.id,
    );
    await _projectRepository.saveProject(updatedProject);
    return copy.id;
  }

  /// Shows or hides layer [id]. Hidden layers are neither rendered nor exported
  /// and are deselected; they remain listed in the layers panel.
  Future<void> toggleVisibility(String id) async {
    final layers = _current.project.layers;
    final index = layers.indexWhere((l) => l.id == id);
    if (index == -1) return;

    await _historyNotifier.pushState(layers);

    final toggled = layers[index].copyWith(isVisible: !layers[index].isVisible);
    final updatedList = List<CanvasLayer>.from(layers)..[index] = toggled;
    final updatedProject = _current.project.copyWith(
      layers: updatedList,
      updatedAt: DateTime.now(),
    );

    _current = _current.copyWith(
      project: updatedProject,
      selectedLayerId: !toggled.isVisible && _current.selectedLayerId == id
          ? () => null
          : null,
    );
    await _projectRepository.saveProject(updatedProject);
  }

  /// Places [cutout] directly above the image layer [sourceId] with the same
  /// position, scale and rotation, hides the source and selects the cutout.
  ///
  /// One undo step restores the original image. Does nothing if the source
  /// no longer exists.
  Future<void> applyCutout(String sourceId, ImageLayer cutout) async {
    final layers = _current.project.layers;
    final index = layers.indexWhere((l) => l.id == sourceId);
    if (index == -1) return;

    await _historyNotifier.pushState(layers);

    final source = layers[index];
    final placed = cutout.copyWith(
      x: source.x,
      y: source.y,
      scale: source.scale,
      rotation: source.rotation,
      isFlippedHorizontally:
          source is ImageLayer ? source.isFlippedHorizontally : null,
    );
    final updatedList = List<CanvasLayer>.from(layers)
      ..[index] = source.copyWith(isVisible: false)
      ..insert(index + 1, placed);
    final updatedProject = _current.project.copyWith(
      layers: _reIndexLayers(updatedList),
      updatedAt: DateTime.now(),
    );

    _current = _current.copyWith(
      project: updatedProject,
      selectedLayerId: () => placed.id,
    );
    await _projectRepository.saveProject(updatedProject);
  }

  /// Reverts to the previous state recorded in the [HistoryNotifier].
  Future<void> undo() async {
    final previousLayers = await _historyNotifier.undo(_current.project.layers);
    if (previousLayers != null) {
      final updatedProject = _current.project.copyWith(
        layers: previousLayers,
        updatedAt: DateTime.now(),
      );

      _current = _current.copyWith(
        project: updatedProject,
        selectedLayerId: updatedProject.layers.any((l) => l.id == _current.selectedLayerId)
            ? () => _current.selectedLayerId
            : () => null,
      );

      await _projectRepository.saveProject(updatedProject);
    }
  }

  /// Re-applies the forward state from the [HistoryNotifier].
  Future<void> redo() async {
    final nextLayers = await _historyNotifier.redo(_current.project.layers);
    if (nextLayers != null) {
      final updatedProject = _current.project.copyWith(
        layers: nextLayers,
        updatedAt: DateTime.now(),
      );

      _current = _current.copyWith(
        project: updatedProject,
        selectedLayerId: updatedProject.layers.any((l) => l.id == _current.selectedLayerId)
            ? () => _current.selectedLayerId
            : () => null,
      );

      await _projectRepository.saveProject(updatedProject);
    }
  }

  /// Helper re-assigning sequential zIndex indices (0 to N-1) across layers.
  List<CanvasLayer> _reIndexLayers(List<CanvasLayer> layers) {
    final result = <CanvasLayer>[];
    for (var i = 0; i < layers.length; i++) {
      result.add(layers[i].copyWith(zIndex: i));
    }
    return result;
  }
}
