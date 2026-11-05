import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('HistoryManager (persistent 500-step engine)', () {
    late Directory tempDir;
    late LazyBox<dynamic> historyBox;
    late HistoryManager manager;
    const testProjectId = 'proj-undo-test-1';

    setUpAll(AppBootstrap.registerAdapters);

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_history_test_');
      Hive.init(tempDir.path);
      historyBox = await Hive.openLazyBox<dynamic>(
        HistoryManager.boxNameFor(testProjectId),
      );
      manager = HistoryManager(projectId: testProjectId, historyBox: historyBox);
    });

    tearDown(() async {
      await manager.dispose();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    TextLayer makeTextLayer(int index) {
      return TextLayer(id: 'layer-$index', x: 0.5, y: 0.5, text: 'State $index');
    }

    CanvasSnapshot snapshot(int index) => CanvasSnapshot(layers: [makeTextLayer(index)]);

    String textOf(CanvasSnapshot? snapshot) => (snapshot!.layers.first as TextLayer).text;

    /// Simulates an app restart: closes everything and opens a fresh manager
    /// on the same box file.
    Future<HistoryManager> reopen({int? inMemoryLimit, int? prefetchTrigger}) async {
      await manager.dispose();
      await Hive.close();
      Hive.init(tempDir.path);
      historyBox = await Hive.openLazyBox<dynamic>(
        HistoryManager.boxNameFor(testProjectId),
      );
      manager = HistoryManager(
        projectId: testProjectId,
        historyBox: historyBox,
        inMemoryLimit: inMemoryLimit,
        prefetchTrigger: prefetchTrigger,
      );
      await manager.load();
      return manager;
    }

    test('initial state has empty stacks', () async {
      await manager.load();

      expect(manager.isLoaded, isTrue);
      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isFalse);
      expect(manager.inMemoryUndoCount, 0);
      expect(manager.diskUndoCount, 0);
      expect(manager.totalUndoCount, 0);
      expect(manager.redoCount, 0);
    });

    test('push, undo, and redo cycles maintain correct layer states', () async {
      await manager.pushState(snapshot(1));
      await manager.pushState(snapshot(2));

      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isFalse);
      expect(manager.totalUndoCount, 2);

      expect(await manager.undo(snapshot(3)), equals(snapshot(2)));
      expect(manager.canRedo, isTrue);
      expect(await manager.undo(snapshot(2)), equals(snapshot(1)));
      expect(await manager.redo(snapshot(1)), equals(snapshot(2)));
    });

    test('undo with nothing to undo returns null and leaves redo untouched', () async {
      expect(await manager.undo(snapshot(1)), isNull);
      expect(manager.canRedo, isFalse);
      expect(manager.redoCount, 0);
    });

    test('redo with nothing to redo returns null and leaves undo untouched', () async {
      await manager.pushState(snapshot(1));

      expect(await manager.redo(snapshot(2)), isNull);
      expect(manager.totalUndoCount, 1);
    });

    test('pushing a new state invalidates the redo branch on disk', () async {
      await manager.pushState(snapshot(1));
      await manager.pushState(snapshot(2));
      await manager.undo(snapshot(3));
      await manager.undo(snapshot(2));
      expect(manager.redoCount, 2);

      await manager.pushState(snapshot(99));

      expect(manager.canRedo, isFalse);
      expect(manager.redoCount, 0);
      expect(await historyBox.get(HistoryManager.redoKeyBase), isNull);
      expect(await historyBox.get(HistoryManager.redoKeyBase + 1), isNull);
    });

    test('RAM cache is capped at 50 while every snapshot is written to disk', () async {
      for (var i = 1; i <= 60; i++) {
        await manager.pushState(snapshot(i));
      }

      expect(manager.inMemoryUndoCount, 50);
      expect(manager.diskUndoCount, 10);
      expect(manager.totalUndoCount, 60);
      // 60 snapshots + the meta record.
      expect(historyBox.length, 61);
    });

    test('undoing past the RAM window restores the earliest states from disk', () async {
      for (var i = 1; i <= 60; i++) {
        await manager.pushState(snapshot(i));
      }

      var current = snapshot(61);
      for (var i = 60; i >= 1; i--) {
        final previous = await manager.undo(current);
        expect(textOf(previous), 'State $i');
        current = previous!;
      }

      expect(manager.canUndo, isFalse);
    });

    test('prefetch refills the RAM window in the background when it runs low', () async {
      manager = HistoryManager(
        projectId: testProjectId,
        historyBox: historyBox,
        inMemoryLimit: 10,
        prefetchTrigger: 3,
      );
      for (var i = 1; i <= 30; i++) {
        await manager.pushState(snapshot(i));
      }
      expect(manager.inMemoryUndoCount, 10);

      var current = snapshot(31);
      for (var i = 0; i < 8; i++) {
        current = (await manager.undo(current))!;
      }
      await manager.flushPrefetch();

      expect(manager.inMemoryUndoCount, 10);
      expect(manager.totalUndoCount, 22);
      expect(manager.isPrefetching, isFalse);
    });

    test('enforces the maxDepth ceiling by evicting the oldest snapshots', () async {
      manager = HistoryManager(
        projectId: testProjectId,
        historyBox: historyBox,
        maxDepth: 15,
        inMemoryLimit: 5,
        prefetchTrigger: 2,
      );

      for (var i = 1; i <= 25; i++) {
        await manager.pushState(snapshot(i));
      }

      expect(manager.inMemoryUndoCount, 5);
      expect(manager.diskUndoCount, 10);
      expect(manager.totalUndoCount, 15);
      expect(await historyBox.get(9), isNull, reason: 'State 10 was evicted');

      // The oldest reachable state is now State 11.
      var current = snapshot(26);
      CanvasSnapshot? last;
      while (manager.canUndo) {
        last = await manager.undo(current);
        current = last!;
      }
      expect(textOf(last), 'State 11');
    });

    test('undo and redo history survive an app restart', () async {
      for (var i = 1; i <= 70; i++) {
        await manager.pushState(snapshot(i));
      }
      await manager.undo(snapshot(71));
      await manager.undo(snapshot(70));

      final restarted = await reopen();

      expect(restarted.totalUndoCount, 68);
      expect(restarted.redoCount, 2);
      expect(restarted.inMemoryUndoCount, 50);
      expect(textOf(await restarted.undo(snapshot(69))), 'State 68');
      expect(textOf(await restarted.redo(snapshot(68))), 'State 69');
      expect(textOf(await restarted.redo(snapshot(69))), 'State 70');
    });

    test('a missing snapshot on disk truncates history instead of misaligning', () async {
      manager = HistoryManager(
        projectId: testProjectId,
        historyBox: historyBox,
        inMemoryLimit: 5,
      );
      for (var i = 1; i <= 12; i++) {
        await manager.pushState(snapshot(i));
      }
      // Simulate a lost write for State 4 (key 3), outside the RAM window.
      await historyBox.delete(3);

      final restarted = await reopen(inMemoryLimit: 5, prefetchTrigger: 1);

      var current = snapshot(13);
      final reverted = <String>[];
      while (restarted.canUndo) {
        final previous = await restarted.undo(current);
        if (previous == null) break;
        reverted.add(textOf(previous));
        current = previous;
      }

      expect(reverted.first, 'State 12');
      expect(reverted.last, 'State 5');
      expect(restarted.canUndo, isFalse);
    });

    test('frames saved before snapshots existed read as a white background', () async {
      // Older app versions stored each frame as a plain list of layers.
      await historyBox.put(0, <CanvasLayer>[makeTextLayer(1)]);
      await historyBox.put(HistoryManager.metaKey, <int>[0, 1, 0]);

      final restarted = await reopen();
      final restored = await restarted.undo(snapshot(2));

      expect(textOf(restored), 'State 1');
      expect(restored!.backgroundColorValue, CanvasSnapshot.defaultBackgroundColor);
    });

    test('clear purges RAM and disk', () async {
      for (var i = 1; i <= 55; i++) {
        await manager.pushState(snapshot(i));
      }

      await manager.clear();

      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isFalse);
      expect(manager.totalUndoCount, 0);
      expect(manager.inMemoryUndoCount, 0);
      expect(historyBox.isEmpty, isTrue);
    });

    test('deleteFromDisk removes the persisted history of a project', () async {
      await manager.pushState(snapshot(1));
      await manager.dispose();

      await HistoryManager.deleteFromDisk(testProjectId);

      final fresh = await Hive.openLazyBox<dynamic>(
        HistoryManager.boxNameFor(testProjectId),
      );
      expect(fresh.isEmpty, isTrue);
    });

    test('HistoryNotifier publishes metrics, including after loading from disk', () async {
      await manager.pushState(snapshot(1));
      await manager.pushState(snapshot(2));
      final restarted = await reopen();
      // A manager that has not loaded yet, as on a cold start.
      final coldManager = HistoryManager(projectId: testProjectId, historyBox: historyBox);
      addTearDown(coldManager.dispose);
      expect(restarted.totalUndoCount, 2);

      final container = ProviderContainer(
        overrides: [historyManagerProvider(testProjectId).overrideWithValue(coldManager)],
      );
      addTearDown(container.dispose);
      container.listen(historyProvider(testProjectId), (_, _) {});

      expect(container.read(historyProvider(testProjectId)).canUndo, isFalse);
      await coldManager.load();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(historyProvider(testProjectId)).totalUndoCount, 2);

      final notifier = container.read(historyProvider(testProjectId).notifier);
      await notifier.undo(snapshot(3));
      final state = container.read(historyProvider(testProjectId));
      expect(state.canRedo, isTrue);
      expect(state.totalUndoCount, 1);
    });
  });
}
