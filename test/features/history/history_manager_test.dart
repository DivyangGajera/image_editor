import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('HistoryManager (500-step Dual-Tier Engine)', () {
    late Directory tempDir;
    late Box<List<dynamic>> historyBox;
    late HistoryManager manager;
    const testProjectId = 'proj-undo-test-1';

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ImageLayerAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TextLayerAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DoodleLayerAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(StickerLayerAdapter());
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_history_test_');
      Hive.init(tempDir.path);
      historyBox = await Hive.openBox<List<dynamic>>('history_$testProjectId');

      manager = HistoryManager(
        projectId: testProjectId,
        historyBox: historyBox,
      );
    });

    tearDown(() async {
      await manager.dispose();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    TextLayer makeTextLayer(int index) {
      return TextLayer(
        id: 'layer-$index',
        x: 0.5,
        y: 0.5,
        text: 'State $index',
      );
    }

    test('initial state has empty stacks', () {
      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isFalse);
      expect(manager.inMemoryUndoCount, 0);
      expect(manager.diskUndoCount, 0);
      expect(manager.totalUndoCount, 0);
      expect(manager.redoCount, 0);
    });

    test('push, undo, and redo cycles maintain correct layer states', () async {
      final state1 = <CanvasLayer>[makeTextLayer(1)];
      final state2 = <CanvasLayer>[makeTextLayer(2)];
      final state3 = <CanvasLayer>[makeTextLayer(3)];

      await manager.pushState(state1);
      await manager.pushState(state2);

      expect(manager.canUndo, isTrue);
      expect(manager.canRedo, isFalse);
      expect(manager.totalUndoCount, 2);

      // Undo from state 3 to state 2
      final undoneToState2 = await manager.undo(state3);
      expect(undoneToState2, equals(state2));
      expect(manager.canRedo, isTrue);

      // Undo from state 2 to state 1
      final undoneToState1 = await manager.undo(state2);
      expect(undoneToState1, equals(state1));

      // Redo back to state 2
      final redoneToState2 = await manager.redo(state1);
      expect(redoneToState2, equals(state2));
    });

    test('pushing new state invalidates redo stack', () async {
      final s1 = <CanvasLayer>[makeTextLayer(1)];
      final s2 = <CanvasLayer>[makeTextLayer(2)];
      final sBranch = <CanvasLayer>[makeTextLayer(99)];

      await manager.pushState(s1);
      await manager.pushState(s2);

      // Undo to s1, so s2 is on redo stack
      await manager.undo(s2);
      expect(manager.canRedo, isTrue);
      expect(manager.redoCount, 1);

      // Push alternative branch
      await manager.pushState(sBranch);
      expect(manager.canRedo, isFalse);
      expect(manager.redoCount, 0);
    });

    test('memory boundary spillover: pushing 60 actions caps RAM at 50 and spills 10 to disk', () async {
      for (var i = 1; i <= 60; i++) {
        await manager.pushState(<CanvasLayer>[makeTextLayer(i)]);
      }

      // Assert RAM ceiling
      expect(manager.inMemoryUndoCount, 50);
      expect(manager.inMemoryUndoCount, lessThanOrEqualTo(50));

      // Assert Hive disk spillover count
      expect(manager.diskUndoCount, 10);
      expect(manager.totalUndoCount, 60);
      expect(historyBox.length, 10);
    });

    test('disk recovery: un-doing through spillover restores earliest pushed states', () async {
      for (var i = 1; i <= 60; i++) {
        await manager.pushState(<CanvasLayer>[makeTextLayer(i)]);
      }

      var current = <CanvasLayer>[makeTextLayer(61)];

      // Undo 59 times down to the first state
      for (var i = 60; i >= 2; i--) {
        final previous = await manager.undo(current);
        expect(previous, isNotNull);
        expect((previous!.first as TextLayer).text, 'State $i');
        current = previous;
      }

      // Final undo gives State 1
      final state1 = await manager.undo(current);
      expect(state1, isNotNull);
      expect((state1!.first as TextLayer).text, 'State 1');

      // Now stack is exhausted
      expect(manager.canUndo, isFalse);
    });

    test('enforces maxDepth ceiling by purging oldest disk frames', () async {
      final customManager = HistoryManager(
        projectId: 'custom-cap-test',
        historyBox: historyBox,
        maxDepth: 15,
        inMemoryLimit: 5,
        prefetchTrigger: 2,
      );

      // Push 25 states (exceeding maxDepth of 15)
      for (var i = 1; i <= 25; i++) {
        await customManager.pushState(<CanvasLayer>[makeTextLayer(i)]);
      }

      // Should be strictly capped at 15
      expect(customManager.inMemoryUndoCount, 5);
      expect(customManager.diskUndoCount, 10);
      expect(customManager.totalUndoCount, 15);
    });

    test('clear purges both in-memory stacks and Hive box', () async {
      for (var i = 1; i <= 55; i++) {
        await manager.pushState(<CanvasLayer>[makeTextLayer(i)]);
      }
      expect(manager.totalUndoCount, 55);

      await manager.clear();

      expect(manager.canUndo, isFalse);
      expect(manager.canRedo, isFalse);
      expect(manager.totalUndoCount, 0);
      expect(manager.inMemoryUndoCount, 0);
      expect(manager.diskUndoCount, 0);
      expect(historyBox.isEmpty, isTrue);
    });

    test('HistoryNotifier updates reactive state in Riverpod container', () async {
      final container = ProviderContainer(
        overrides: <Override>[
          historyManagerProvider(testProjectId).overrideWithValue(manager),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(historyNotifierProvider(testProjectId).notifier);

      expect(container.read(historyNotifierProvider(testProjectId)).canUndo, isFalse);

      await notifier.pushState(<CanvasLayer>[makeTextLayer(1)]);
      final stateAfterPush = container.read(historyNotifierProvider(testProjectId));
      expect(stateAfterPush.canUndo, isTrue);
      expect(stateAfterPush.totalUndoCount, 1);

      final undone = await notifier.undo(<CanvasLayer>[makeTextLayer(2)]);
      expect(undone, isNotNull);
      final stateAfterUndo = container.read(historyNotifierProvider(testProjectId));
      expect(stateAfterUndo.canRedo, isTrue);

      await notifier.redo(<CanvasLayer>[makeTextLayer(1)]);
      final stateAfterRedo = container.read(historyNotifierProvider(testProjectId));
      expect(stateAfterRedo.canRedo, isFalse);
    });
  });
}
