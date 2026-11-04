import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('HistoryNotifier (500-Step Stress & Rapid Firing)', () {
    late Directory tempDir;
    late Box<List<dynamic>> historyBox;
    late HistoryManager historyManager;
    late ProviderContainer container;
    const testProjectId = 'proj-notifier-stress-1';

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ImageLayerAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TextLayerAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DoodleLayerAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(StickerLayerAdapter());
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_notifier_test_');
      Hive.init(tempDir.path);
      historyBox = await Hive.openBox<List<dynamic>>('history_$testProjectId');

      historyManager = HistoryManager(
        projectId: testProjectId,
        historyBox: historyBox,
      );

      container = ProviderContainer(
        overrides: [
          historyManagerProvider(testProjectId).overrideWithValue(historyManager),
        ],
      );
      // Keep the auto-disposed history provider alive for the whole test.
      container.listen(historyProvider(testProjectId), (_, _) {});
    });

    tearDown(() async {
      container.dispose();
      await historyManager.dispose();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    TextLayer makeTextLayer(int index) {
      return TextLayer(
        id: 'layer-$index',
        x: (index % 100) / 100.0,
        y: (index % 100) / 100.0,
        text: 'Step $index',
      );
    }

    test('initial state has empty stacks', () {
      final state = container.read(historyProvider(testProjectId));
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
      expect(state.totalUndoCount, equals(0));
      expect(state.inMemoryUndoCount, equals(0));
      expect(state.diskUndoCount, equals(0));
      expect(state.redoCount, equals(0));
    });

    test('500-step rapid event firing accumulates full 500-step dual-tier history', () async {
      final notifier = container.read(historyProvider(testProjectId).notifier);

      // Rapidly fire 500 state changes
      for (int i = 1; i <= 500; i++) {
        await notifier.pushState([makeTextLayer(i)]);
      }

      final state = container.read(historyProvider(testProjectId));
      expect(state.canUndo, isTrue);
      expect(state.canRedo, isFalse);
      expect(state.totalUndoCount, equals(500));
      // Max 50 states cached in memory, remainder persisted to disk
      expect(state.inMemoryUndoCount, lessThanOrEqualTo(50));
      expect(state.diskUndoCount, greaterThanOrEqualTo(450));
      expect(state.inMemoryUndoCount + state.diskUndoCount, equals(500));
    });

    test('complete 500-step rollback and redo cycles correctly across RAM & disk tiers', () async {
      final notifier = container.read(historyProvider(testProjectId).notifier);

      // 1. Push 500 states
      for (int i = 1; i <= 500; i++) {
        await notifier.pushState([makeTextLayer(i)]);
      }

      expect(container.read(historyProvider(testProjectId)).totalUndoCount, equals(500));

      // 2. Rollback all 500 steps in reverse order
      List<CanvasLayer> currentLayers = [
        const TextLayer(id: 'active', x: 0.5, y: 0.5, text: 'Active State'),
      ];

      for (int i = 500; i >= 1; i--) {
        final reverted = await notifier.undo(currentLayers);
        expect(reverted, isNotNull, reason: 'Failed to revert at step $i');
        expect(reverted!.length, equals(1));
        final layer = reverted.first as TextLayer;
        expect(layer.text, equals('Step $i'));
        currentLayers = reverted;
      }

      var state = container.read(historyProvider(testProjectId));
      expect(state.totalUndoCount, equals(0));
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isTrue);
      expect(state.redoCount, equals(500));

      // 3. Redo all 500 steps forward
      for (int i = 1; i <= 500; i++) {
        final restored = await notifier.redo(currentLayers);
        expect(restored, isNotNull, reason: 'Failed to redo at step $i');
        expect(restored!.length, equals(1));
        final layer = restored.first as TextLayer;
        expect(
          layer.text,
          i == 500 ? 'Active State' : 'Step ${i + 1}',
        );
        currentLayers = restored;
      }

      state = container.read(historyProvider(testProjectId));
      expect(state.redoCount, equals(0));
      expect(state.canRedo, isFalse);
      expect(state.canUndo, isTrue);
      expect(state.totalUndoCount, equals(500));
    });

    test('pushing new state after undo truncates redo stack correctly', () async {
      final notifier = container.read(historyProvider(testProjectId).notifier);

      // Push 50 states
      for (int i = 1; i <= 50; i++) {
        await notifier.pushState([makeTextLayer(i)]);
      }

      // Undo 20 steps
      List<CanvasLayer> current = [makeTextLayer(51)];
      for (int i = 0; i < 20; i++) {
        final res = await notifier.undo(current);
        current = res!;
      }

      var state = container.read(historyProvider(testProjectId));
      expect(state.totalUndoCount, equals(30));
      expect(state.redoCount, equals(20));
      expect(state.canRedo, isTrue);

      // Now push a new divergent branch state
      await notifier.pushState([
        const TextLayer(id: 'divergent', x: 0.9, y: 0.9, text: 'Branch State'),
      ]);

      state = container.read(historyProvider(testProjectId));
      expect(state.totalUndoCount, equals(31));
      expect(state.redoCount, equals(0));
      expect(state.canRedo, isFalse);
    });

    test('clear purges all history states and resets metrics', () async {
      final notifier = container.read(historyProvider(testProjectId).notifier);

      for (int i = 1; i <= 10; i++) {
        await notifier.pushState([makeTextLayer(i)]);
      }

      expect(container.read(historyProvider(testProjectId)).canUndo, isTrue);

      await notifier.clear();

      final state = container.read(historyProvider(testProjectId));
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
      expect(state.totalUndoCount, equals(0));
      expect(state.redoCount, equals(0));
    });
  });
}
