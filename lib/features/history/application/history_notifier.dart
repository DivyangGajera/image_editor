import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_editor/core/utils/app_logger.dart';
import 'package:image_editor/features/history/data/history_manager.dart';
import 'package:image_editor/features/history/domain/canvas_snapshot.dart';
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
    if (!_manager.isLoaded) {
      // Persisted history is read asynchronously; publish metrics once loaded.
      unawaited(
        _manager.load().then(
          (_) => _publish(),
          onError: (Object error, StackTrace stackTrace) {
            // History stays empty; editing keeps working without undo.
            AppLogger.error(
              'Failed to load undo history for project $projectId',
              tag: 'History',
              error: error,
              stackTrace: stackTrace,
            );
          },
        ),
      );
    }
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

  /// Publishes fresh metrics, unless this notifier was disposed while an
  /// operation was awaiting disk I/O (e.g. the editor closed).
  void _publish() {
    if (ref.mounted) state = _computeState();
  }

  /// Pushes an updated snapshot of layers into the undo history.
  Future<void> pushState(CanvasSnapshot snapshot) async {
    await _manager.pushState(snapshot);
    _publish();
  }

  /// Reverts to the previous state and moves current layers to redo.
  Future<CanvasSnapshot?> undo(CanvasSnapshot current) async {
    final result = await _manager.undo(current);
    _publish();
    return result;
  }

  /// Restores the forward state and moves current layers to undo.
  Future<CanvasSnapshot?> redo(CanvasSnapshot current) async {
    final result = await _manager.redo(current);
    _publish();
    return result;
  }

  /// Purges both undo and redo histories.
  Future<void> clear() async {
    await _manager.clear();
    _publish();
  }
}
