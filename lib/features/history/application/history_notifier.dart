import 'package:flutter/foundation.dart';
import 'package:image_editor/features/history/data/history_manager.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_notifier.g.dart';

/// Immutable state model exposing the active undo/redo metrics.
@immutable
class HistoryState {
  const HistoryState({
    this.canUndo = false,
    this.canRedo = false,
    this.inMemoryUndoCount = 0,
    this.diskUndoCount = 0,
    this.totalUndoCount = 0,
    this.redoCount = 0,
    this.isPrefetching = false,
  });

  final bool canUndo;
  final bool canRedo;
  final int inMemoryUndoCount;
  final int diskUndoCount;
  final int totalUndoCount;
  final int redoCount;
  final bool isPrefetching;

  HistoryState copyWith({
    bool? canUndo,
    bool? canRedo,
    int? inMemoryUndoCount,
    int? diskUndoCount,
    int? totalUndoCount,
    int? redoCount,
    bool? isPrefetching,
  }) {
    return HistoryState(
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      inMemoryUndoCount: inMemoryUndoCount ?? this.inMemoryUndoCount,
      diskUndoCount: diskUndoCount ?? this.diskUndoCount,
      totalUndoCount: totalUndoCount ?? this.totalUndoCount,
      redoCount: redoCount ?? this.redoCount,
      isPrefetching: isPrefetching ?? this.isPrefetching,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryState &&
        other.canUndo == canUndo &&
        other.canRedo == canRedo &&
        other.inMemoryUndoCount == inMemoryUndoCount &&
        other.diskUndoCount == diskUndoCount &&
        other.totalUndoCount == totalUndoCount &&
        other.redoCount == redoCount &&
        other.isPrefetching == isPrefetching;
  }

  @override
  int get hashCode => Object.hash(
        canUndo,
        canRedo,
        inMemoryUndoCount,
        diskUndoCount,
        totalUndoCount,
        redoCount,
        isPrefetching,
      );

  @override
  String toString() =>
      'HistoryState(canUndo: $canUndo, canRedo: $canRedo, totalUndo: $totalUndoCount '
      '[RAM: $inMemoryUndoCount, Disk: $diskUndoCount], redo: $redoCount, prefetching: $isPrefetching)';
}

/// Project-scoped [HistoryManager]. Disposed (and its Hive box closed) when the
/// last listener of the project's history goes away.
@riverpod
HistoryManager historyManager(Ref ref, String projectId) {
  final manager = HistoryManager(projectId: projectId);
  ref.onDispose(manager.dispose);
  return manager;
}

/// Riverpod notifier coordinating canvas undo/redo history operations.
@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  late HistoryManager _manager;

  @override
  HistoryState build(String projectId) {
    _manager = ref.watch(historyManagerProvider(projectId));
    return _computeState();
  }

  HistoryState _computeState() {
    return HistoryState(
      canUndo: _manager.canUndo,
      canRedo: _manager.canRedo,
      inMemoryUndoCount: _manager.inMemoryUndoCount,
      diskUndoCount: _manager.diskUndoCount,
      totalUndoCount: _manager.totalUndoCount,
      redoCount: _manager.redoCount,
      isPrefetching: _manager.isPrefetching,
    );
  }

  /// Pushes an updated snapshot of layers into the undo history.
  Future<void> pushState(List<CanvasLayer> layers) async {
    await _manager.pushState(layers);
    state = _computeState();
  }

  /// Reverts to the previous state and moves current layers to redo.
  Future<List<CanvasLayer>?> undo(List<CanvasLayer> currentLayers) async {
    final result = await _manager.undo(currentLayers);
    state = _computeState();
    return result;
  }

  /// Restores the forward state and moves current layers to undo.
  Future<List<CanvasLayer>?> redo(List<CanvasLayer> currentLayers) async {
    final result = await _manager.redo(currentLayers);
    state = _computeState();
    return result;
  }

  /// Purges both undo and redo histories.
  Future<void> clear() async {
    await _manager.clear();
    state = _computeState();
  }
}
