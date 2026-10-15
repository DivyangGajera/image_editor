import 'dart:async';
import 'dart:math';

import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Memory-efficient Undo/Redo Engine with a 500-step maximum depth.
///
/// Maintains up to 50 active snapshots in RAM. When exceeding this threshold,
/// older frames spill over into a dedicated Hive CE box (`history_<projectId>`).
/// Pre-fetches preceding frames asynchronously when undo depth in RAM drops below 5.
class HistoryManager {
  HistoryManager({
    required this.projectId,
    this.historyBox,
    int? maxDepth,
    int? inMemoryLimit,
    int? prefetchTrigger,
  })  : maxDepth = maxDepth ?? AppConstants.maxUndoHistoryDepth,
        inMemoryLimit = inMemoryLimit ?? AppConstants.inMemoryHistoryDepth,
        prefetchTrigger = prefetchTrigger ?? AppConstants.historyPrefetchThreshold;

  final String projectId;
  final int maxDepth;
  final int inMemoryLimit;
  final int prefetchTrigger;

  Box<List<dynamic>>? historyBox;

  final List<List<CanvasLayer>> _undoStack = <List<CanvasLayer>>[];
  final List<List<CanvasLayer>> _redoStack = <List<CanvasLayer>>[];

  int _diskBottomKey = 0;
  int _diskTopKey = 0;
  int _diskCount = 0;
  bool _isPrefetching = false;
  Future<void>? _prefetchFuture;

  /// Whether prefetching is currently executing.
  bool get isPrefetching => _isPrefetching;

  /// Current number of undo snapshots retained in RAM.
  int get inMemoryUndoCount => _undoStack.length;

  /// Current number of undo snapshots persisted to disk.
  int get diskUndoCount => _diskCount;

  /// Total accessible undo steps across RAM and disk.
  int get totalUndoCount => _undoStack.length + _diskCount;

  /// Current number of redo snapshots in RAM.
  int get redoCount => _redoStack.length;

  /// Whether undo can be invoked.
  bool get canUndo => _undoStack.isNotEmpty || _diskCount > 0;

  /// Whether redo can be invoked.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Box name for project-specific history.
  String get boxName => '${StorageKeys.historyBoxPrefix}$projectId';

  Future<Box<List<dynamic>>> _getBox() async {
    if (historyBox != null && historyBox!.isOpen) {
      return historyBox!;
    }
    if (Hive.isBoxOpen(boxName)) {
      historyBox = Hive.box<List<dynamic>>(boxName);
    } else {
      historyBox = await Hive.openBox<List<dynamic>>(boxName);
    }
    return historyBox!;
  }

  /// Pushes a new canvas state onto the undo stack and clears redo history.
  ///
  /// Spills the oldest in-memory frame to disk when exceeding [inMemoryLimit].
  Future<void> pushState(List<CanvasLayer> layers) async {
    // Invalidate redo stack upon pushing any new action branch
    _redoStack.clear();

    // Deep copy layers to guarantee state immutability
    final clonedSnapshot = layers.map((layer) => layer.copyWith()).toList();
    _undoStack.add(clonedSnapshot);

    // Check disk spillover
    if (_undoStack.length > inMemoryLimit) {
      final oldestInMemory = _undoStack.removeAt(0);
      final box = await _getBox();

      await box.put(_diskTopKey, oldestInMemory);
      _diskTopKey++;
      _diskCount++;

      // Enforce total history depth ceiling
      if (_diskCount + _undoStack.length > maxDepth) {
        await box.delete(_diskBottomKey);
        _diskBottomKey++;
        _diskCount--;
      }
    }
  }

  /// Reverts the canvas to the preceding state and pushes [currentLayers] onto the redo stack.
  ///
  /// Asynchronously triggers pre-fetching from disk if in-memory frames drop below [prefetchTrigger].
  Future<List<CanvasLayer>?> undo(List<CanvasLayer> currentLayers) async {
    if (!canUndo) return null;

    // Push current state to redo stack
    _redoStack.add(currentLayers.map((layer) => layer.copyWith()).toList());

    // If an asynchronous prefetch is ongoing, await it before checking stack
    if (_prefetchFuture != null && _isPrefetching) {
      await _prefetchFuture;
    }

    // If undo stack is empty in RAM but disk has frames, force synchronous recovery
    if (_undoStack.isEmpty && _diskCount > 0) {
      await _prefetchFromDisk();
    }

    if (_undoStack.isEmpty) return null;

    final targetState = _undoStack.removeLast();

    // Asynchronously pre-fetch earlier frames from disk if RAM stack is low
    if (_undoStack.length < prefetchTrigger && _diskCount > 0 && !_isPrefetching) {
      _prefetchFuture = _prefetchFromDisk();
    }

    return targetState.map((layer) => layer.copyWith()).toList();
  }

  /// Re-applies the next forward state from the redo stack.
  Future<List<CanvasLayer>?> redo(List<CanvasLayer> currentLayers) async {
    if (!canRedo) return null;

    final nextState = _redoStack.removeLast();

    // Deep copy current layers into undo stack
    _undoStack.add(currentLayers.map((layer) => layer.copyWith()).toList());

    // Check disk spillover if redoing pushes undo stack past inMemoryLimit
    if (_undoStack.length > inMemoryLimit) {
      final oldest = _undoStack.removeAt(0);
      final box = await _getBox();
      await box.put(_diskTopKey, oldest);
      _diskTopKey++;
      _diskCount++;

      if (_diskCount + _undoStack.length > maxDepth) {
        await box.delete(_diskBottomKey);
        _diskBottomKey++;
        _diskCount--;
      }
    }

    return nextState.map((layer) => layer.copyWith()).toList();
  }

  /// Asynchronously reads up to [inMemoryLimit] frames from disk Hive box
  /// and prepends them chronologically into the bottom of [_undoStack].
  Future<void> _prefetchFromDisk() async {
    if (_isPrefetching || _diskCount <= 0) return;
    _isPrefetching = true;

    try {
      final box = await _getBox();
      if (!box.isOpen) return;

      final availableSlots = inMemoryLimit - _undoStack.length;
      if (availableSlots <= 0) return;

      final countToFetch = min(availableSlots, _diskCount);
      final fetchedBatch = <List<CanvasLayer>>[];

      for (var i = 0; i < countToFetch; i++) {
        if (!box.isOpen) break;
        final keyToRead = _diskTopKey - 1 - i;
        final raw = box.get(keyToRead);
        if (raw != null) {
          final layers = raw.cast<CanvasLayer>();
          fetchedBatch.insert(0, layers);
        }
        await box.delete(keyToRead);
      }

      _diskTopKey -= countToFetch;
      _diskCount -= countToFetch;

      // Prepend recovered batch to the bottom of the undo stack
      _undoStack.insertAll(0, fetchedBatch);
    } catch (_) {
      // Gracefully handle if box is closed during shutdown
    } finally {
      _isPrefetching = false;
    }
  }

  /// Forces an immediate synchronous flush and prefetch for deterministic testing.
  Future<void> flushPrefetch() async {
    if (_diskCount > 0) {
      await _prefetchFromDisk();
    }
  }

  /// Clears in-memory stacks and purges all persisted snapshots in the Hive box.
  Future<void> clear() async {
    if (_prefetchFuture != null) {
      try {
        await _prefetchFuture;
      } catch (_) {}
    }
    _undoStack.clear();
    _redoStack.clear();
    _diskBottomKey = 0;
    _diskTopKey = 0;
    _diskCount = 0;

    final box = await _getBox();
    if (box.isOpen) {
      await box.clear();
    }
  }

  /// Closes the underlying Hive box after finishing any pending prefetch.
  Future<void> dispose() async {
    if (_prefetchFuture != null) {
      try {
        await _prefetchFuture;
      } catch (_) {}
    }
    if (historyBox != null && historyBox!.isOpen) {
      await historyBox!.close();
    }
  }
}
