import 'dart:async';
import 'dart:math';

import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/history/domain/canvas_snapshot.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Persistent, memory-bounded undo/redo engine (default 500 steps) for one project.
///
/// **Disk is the source of truth.** Every snapshot is written through to a
/// project-specific Hive [LazyBox] (`history_<projectId>`) whose values are only
/// read on demand, so undo/redo history survives app restarts without loading
/// all 500 snapshots into memory.
///
/// **RAM is a cache window** holding at most [inMemoryLimit] of the newest undo
/// snapshots. When successive undos shrink the window below [prefetchTrigger],
/// the next batch of older snapshots is prefetched from disk in the background.
///
/// Box layout:
/// * int keys `[undoBottom, undoTop)` — undo snapshots, oldest first.
/// * int keys `redoKeyBase + [0, redoCount)` — redo stack, top is the last key.
/// * `'meta'` — `[undoBottom, undoTop, redoCount]`.
///
/// All public operations run one at a time through an internal queue, so a
/// background prefetch can never interleave with a push, undo or redo.
class HistoryManager {
  HistoryManager({
    required this.projectId,
    LazyBox<dynamic>? historyBox,
    int? maxDepth,
    int? inMemoryLimit,
    int? prefetchTrigger,
  })  : _box = historyBox,
        maxDepth = maxDepth ?? AppConstants.maxUndoHistoryDepth,
        inMemoryLimit = inMemoryLimit ?? AppConstants.inMemoryHistoryDepth,
        prefetchTrigger = prefetchTrigger ?? AppConstants.historyPrefetchThreshold;

  /// Hive key under which the range metadata is stored.
  static const String metaKey = 'meta';

  /// First key of the redo stack, far above any reachable undo key.
  static const int redoKeyBase = 0x40000000;

  /// Box name holding the history of [projectId].
  static String boxNameFor(String projectId) =>
      '${StorageKeys.historyBoxPrefix}$projectId';

  /// Permanently deletes the persisted history of [projectId] (e.g. when the
  /// project itself is deleted). The box must not be open elsewhere.
  static Future<void> deleteFromDisk(String projectId) =>
      Hive.deleteBoxFromDisk(boxNameFor(projectId));

  final String projectId;
  final int maxDepth;
  final int inMemoryLimit;
  final int prefetchTrigger;

  LazyBox<dynamic>? _box;

  /// Newest undo snapshots; covers keys `[_undoTop - length, _undoTop)`.
  final List<CanvasSnapshot> _undoCache = <CanvasSnapshot>[];

  int _undoBottom = 0;
  int _undoTop = 0;
  int _redoCount = 0;

  bool _isLoaded = false;
  bool _isPrefetching = false;
  Future<void> _queue = Future<void>.value();

  /// Name of the backing Hive box.
  String get boxName => boxNameFor(projectId);

  /// Whether persisted history has been read from disk.
  bool get isLoaded => _isLoaded;

  /// Whether a background prefetch from disk is executing.
  bool get isPrefetching => _isPrefetching;

  /// Number of undo snapshots currently cached in RAM.
  int get inMemoryUndoCount => _undoCache.length;

  /// Number of undo snapshots that live only on disk (not cached in RAM).
  int get diskUndoCount => totalUndoCount - _undoCache.length;

  /// Total number of undo steps available across RAM and disk.
  int get totalUndoCount => _undoTop - _undoBottom;

  /// Number of redo steps available.
  int get redoCount => _redoCount;

  bool get canUndo => totalUndoCount > 0;

  bool get canRedo => _redoCount > 0;

  /// Reads persisted history (range metadata plus the newest cached window).
  ///
  /// Safe to call repeatedly; every other operation loads implicitly.
  Future<void> load() => _enqueue(_ensureLoaded);

  /// Records [layers] as the newest undo snapshot and invalidates the redo branch.
  Future<void> pushState(CanvasSnapshot snapshot) {
    return _enqueue(() async {
      await _ensureLoaded();
      await _clearRedo();
      await _pushUndo(snapshot.clone());
      await _writeMeta();
    });
  }

  /// Returns the previous snapshot and stores [currentLayers] on the redo stack.
  ///
  /// Returns `null` without side effects when there is nothing to undo.
  Future<CanvasSnapshot?> undo(CanvasSnapshot current) {
    final result = _enqueue<CanvasSnapshot?>(() async {
      await _ensureLoaded();
      if (!canUndo) return null;

      if (_undoCache.isEmpty) {
        await _prefetchBatch();
        if (_undoCache.isEmpty) return null;
      }

      final box = await _openBox();
      final target = _undoCache.removeLast();
      _undoTop--;
      await box.delete(_undoTop);

      await box.put(redoKeyBase + _redoCount, current.clone());
      _redoCount++;
      await _writeMeta();

      return target.clone();
    });

    // Refill the RAM window in the background once it runs low; queued after
    // this undo so it cannot interleave with it.
    unawaited(result.then((_) => _schedulePrefetchIfLow()));
    return result;
  }

  /// Returns the next snapshot from the redo stack and stores [currentLayers]
  /// as the newest undo snapshot. Returns `null` when there is nothing to redo.
  Future<CanvasSnapshot?> redo(CanvasSnapshot current) {
    return _enqueue(() async {
      await _ensureLoaded();
      if (!canRedo) return null;

      final box = await _openBox();
      final key = redoKeyBase + _redoCount - 1;
      final raw = await box.get(key);
      await box.delete(key);
      _redoCount--;

      await _pushUndo(current.clone());
      await _writeMeta();

      return raw == null ? null : _decode(raw).clone();
    });
  }

  /// Waits for any queued work, including a pending background prefetch.
  Future<void> flushPrefetch() => _enqueue(() async {});

  /// Purges every undo and redo snapshot from RAM and disk.
  Future<void> clear() {
    return _enqueue(() async {
      final box = await _openBox();
      await box.clear();
      _undoCache.clear();
      _undoBottom = 0;
      _undoTop = 0;
      _redoCount = 0;
      _isLoaded = true;
    });
  }

  /// Finishes queued work and closes the backing box.
  Future<void> dispose() async {
    try {
      await _queue;
    } catch (_) {
      // A failed operation was already reported to its caller.
    }
    final box = _box;
    if (box != null && box.isOpen) {
      await box.close();
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<LazyBox<dynamic>> _openBox() async {
    final existing = _box;
    if (existing != null && existing.isOpen) return existing;

    final box = Hive.isBoxOpen(boxName)
        ? Hive.lazyBox<dynamic>(boxName)
        : await Hive.openLazyBox<dynamic>(boxName);
    _box = box;
    return box;
  }

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;
    final box = await _openBox();

    final meta = await box.get(metaKey);
    if (meta is List && meta.length == 3) {
      _undoBottom = meta[0] as int;
      _undoTop = meta[1] as int;
      _redoCount = meta[2] as int;
    }
    _isLoaded = true;

    await _prefetchBatch();
  }

  Future<void> _pushUndo(CanvasSnapshot snapshot) async {
    final box = await _openBox();
    await box.put(_undoTop, snapshot);
    _undoTop++;
    _undoCache.add(snapshot);

    // The snapshot is already on disk, so trimming the cache loses nothing.
    if (_undoCache.length > inMemoryLimit) {
      _undoCache.removeAt(0);
    }

    while (totalUndoCount > maxDepth) {
      await box.delete(_undoBottom);
      _undoBottom++;
    }
    if (_undoCache.length > totalUndoCount) {
      _undoCache.removeRange(0, _undoCache.length - totalUndoCount);
    }
  }

  Future<void> _clearRedo() async {
    if (_redoCount == 0) return;
    final box = await _openBox();
    await box.deleteAll(
      List<int>.generate(_redoCount, (i) => redoKeyBase + i),
    );
    _redoCount = 0;
  }

  Future<void> _writeMeta() async {
    final box = await _openBox();
    await box.put(metaKey, <int>[_undoBottom, _undoTop, _redoCount]);
  }

  void _schedulePrefetchIfLow() {
    if (_undoCache.length < prefetchTrigger && diskUndoCount > 0) {
      unawaited(
        _enqueue(() async {
          _isPrefetching = true;
          try {
            await _prefetchBatch();
          } finally {
            _isPrefetching = false;
          }
        }),
      );
    }
  }

  /// Loads the next older snapshots from disk into the bottom of the RAM cache,
  /// up to [inMemoryLimit] cached snapshots in total.
  ///
  /// Walks from newest to oldest; if a snapshot is missing on disk (e.g. an
  /// interrupted write), history older than the gap is discarded so cached
  /// snapshots always stay aligned with their keys.
  Future<void> _prefetchBatch() async {
    final count = min(inMemoryLimit - _undoCache.length, diskUndoCount);
    if (count <= 0) return;

    final box = await _openBox();
    final firstCachedKey = _undoTop - _undoCache.length;
    final batch = <CanvasSnapshot>[];
    for (var key = firstCachedKey - 1; key >= firstCachedKey - count; key--) {
      final raw = await box.get(key);
      if (raw == null) {
        _undoBottom = key + 1;
        await _writeMeta();
        break;
      }
      batch.insert(0, _decode(raw));
    }
    _undoCache.insertAll(0, batch);
  }

  /// Reads a stored frame. Frames written before snapshots carried the
  /// background color are plain layer lists; those projects were white.
  static CanvasSnapshot _decode(Object? raw) {
    if (raw is CanvasSnapshot) return raw;
    return CanvasSnapshot(layers: (raw as List<dynamic>).cast<CanvasLayer>());
  }
}
