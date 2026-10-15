import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('CanvasNotifier', () {
    late Directory tempDir;
    late Box<ProjectModel> projectsBox;
    late Box<List<dynamic>> historyBox;
    late ProjectRepository projectRepository;
    late HistoryManager historyManager;
    late ProviderContainer container;
    final testDate = DateTime(2026, 10, 15, 12, 0);

    final initialProject = ProjectModel(
      id: 'proj-canvas-test',
      title: 'Canvas Workspace Test',
      canvasWidth: 1080.0,
      canvasHeight: 1920.0,
      layers: const <CanvasLayer>[],
      createdAt: testDate,
      updatedAt: testDate,
    );

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ImageLayerAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TextLayerAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DoodleLayerAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(StickerLayerAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ProjectModelAdapter());
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('canvas_notifier_test_');
      Hive.init(tempDir.path);
      projectsBox = await Hive.openBox<ProjectModel>(StorageKeys.projectsBox);
      historyBox = await Hive.openBox<List<dynamic>>('history_${initialProject.id}');

      projectRepository = ProjectRepository(
        getBaseDir: () async => tempDir,
        projectsBox: projectsBox,
      );

      historyManager = HistoryManager(
        projectId: initialProject.id,
        historyBox: historyBox,
      );

      container = ProviderContainer(
        overrides: <Override>[
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(initialProject.id).overrideWithValue(historyManager),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await historyManager.dispose();
      await projectsBox.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    TextLayer makeText(String id, String text) {
      return TextLayer(id: id, x: 0.5, y: 0.5, text: text);
    }

    test('initial state has empty layers and no selection', () {
      final state = container.read(canvasNotifierProvider(initialProject));

      expect(state.project.id, initialProject.id);
      expect(state.project.layers, isEmpty);
      expect(state.selectedLayerId, isNull);
      expect(state.selectedLayer, isNull);
      expect(state.isInteracting, isFalse);
    });

    test('selectLayer and setInteracting update ephemeral state without modifying history', () {
      final notifier = container.read(canvasNotifierProvider(initialProject).notifier);

      notifier.selectLayer('l-test-1');
      expect(container.read(canvasNotifierProvider(initialProject)).selectedLayerId, 'l-test-1');

      notifier.setInteracting(true);
      expect(container.read(canvasNotifierProvider(initialProject)).isInteracting, isTrue);

      final history = container.read(historyNotifierProvider(initialProject.id));
      expect(history.canUndo, isFalse);
    });

    test('addLayer appends layer, assigns sequential zIndex, auto-selects, and records history', () async {
      final notifier = container.read(canvasNotifierProvider(initialProject).notifier);
      final layer1 = makeText('l-1', 'First');
      final layer2 = makeText('l-2', 'Second');

      await notifier.addLayer(layer1);
      var state = container.read(canvasNotifierProvider(initialProject));
      expect(state.project.layers.length, 1);
      expect(state.project.layers[0].zIndex, 0);
      expect(state.selectedLayerId, 'l-1');

      await notifier.addLayer(layer2);
      state = container.read(canvasNotifierProvider(initialProject));
      expect(state.project.layers.length, 2);
      expect(state.project.layers[0].zIndex, 0);
      expect(state.project.layers[1].zIndex, 1);
      expect(state.selectedLayerId, 'l-2');

      final history = container.read(historyNotifierProvider(initialProject.id));
      expect(history.canUndo, isTrue);
      expect(history.totalUndoCount, 2);
    });

    test('updateLayerTransform modifies target layer and records history', () async {
      final notifier = container.read(canvasNotifierProvider(initialProject).notifier);
      await notifier.addLayer(makeText('l-1', 'Initial'));

      await notifier.updateLayerTransform(
        'l-1',
        x: 0.8,
        y: 0.3,
        scale: 1.5,
        rotation: 0.5,
      );

      final state = container.read(canvasNotifierProvider(initialProject));
      final updated = state.project.layers.first;
      expect(updated.x, 0.8);
      expect(updated.y, 0.3);
      expect(updated.scale, 1.5);
      expect(updated.rotation, 0.5);

      final history = container.read(historyNotifierProvider(initialProject.id));
      expect(history.totalUndoCount, 2);
    });

    test('reorderLayer swaps positions, updates zIndex sequentially, and records history', () async {
      final notifier = container.read(canvasNotifierProvider(initialProject).notifier);
      await notifier.addLayer(makeText('l-0', 'Zero'));
      await notifier.addLayer(makeText('l-1', 'One'));
      await notifier.addLayer(makeText('l-2', 'Two'));

      // Move layer at index 0 to index 2
      await notifier.reorderLayer(0, 2);

      final state = container.read(canvasNotifierProvider(initialProject));
      expect(state.project.layers[0].id, 'l-1');
      expect(state.project.layers[0].zIndex, 0);

      expect(state.project.layers[1].id, 'l-2');
      expect(state.project.layers[1].zIndex, 1);

      expect(state.project.layers[2].id, 'l-0');
      expect(state.project.layers[2].zIndex, 2);
    });

    test('bringToFront and sendToBack update stacking order and zIndex', () async {
      final notifier = container.read(canvasNotifierProvider(initialProject).notifier);
      await notifier.addLayer(makeText('l-0', 'Bottom'));
      await notifier.addLayer(makeText('l-1', 'Middle'));
      await notifier.addLayer(makeText('l-2', 'Top'));

      // Bring 'Bottom' to front
      await notifier.bringToFront('l-0');
      var state = container.read(canvasNotifierProvider(initialProject));
      expect(state.project.layers.last.id, 'l-0');
      expect(state.project.layers.last.zIndex, 2);

      // Send 'Bottom' to back
      await notifier.sendToBack('l-0');
      state = container.read(canvasNotifierProvider(initialProject));
      expect(state.project.layers.first.id, 'l-0');
      expect(state.project.layers.first.zIndex, 0);
    });

    test('deleteLayer removes layer, clears selection if matching, and re-indexes remaining layers', () async {
      final notifier = container.read(canvasNotifierProvider(initialProject).notifier);
      await notifier.addLayer(makeText('l-0', 'Zero'));
      await notifier.addLayer(makeText('l-1', 'One'));
      await notifier.addLayer(makeText('l-2', 'Two'));

      notifier.selectLayer('l-1');
      expect(container.read(canvasNotifierProvider(initialProject)).selectedLayerId, 'l-1');

      await notifier.deleteLayer('l-1');
      final state = container.read(canvasNotifierProvider(initialProject));

      expect(state.project.layers.length, 2);
      expect(state.project.layers.any((l) => l.id == 'l-1'), isFalse);
      expect(state.selectedLayerId, isNull);

      // Verify re-indexed zIndex values
      expect(state.project.layers[0].id, 'l-0');
      expect(state.project.layers[0].zIndex, 0);
      expect(state.project.layers[1].id, 'l-2');
      expect(state.project.layers[1].zIndex, 1);
    });

    test('undo and redo revert and re-apply canvas layer states', () async {
      final notifier = container.read(canvasNotifierProvider(initialProject).notifier);
      final l1 = makeText('l-1', 'First');
      final l2 = makeText('l-2', 'Second');

      await notifier.addLayer(l1);
      await notifier.addLayer(l2);

      expect(container.read(canvasNotifierProvider(initialProject)).project.layers.length, 2);

      // Undo addition of l2
      await notifier.undo();
      var state = container.read(canvasNotifierProvider(initialProject));
      expect(state.project.layers.length, 1);
      expect(state.project.layers.first.id, 'l-1');

      // Undo addition of l1
      await notifier.undo();
      state = container.read(canvasNotifierProvider(initialProject));
      expect(state.project.layers, isEmpty);

      // Redo addition of l1
      await notifier.redo();
      state = container.read(canvasNotifierProvider(initialProject));
      expect(state.project.layers.length, 1);
      expect(state.project.layers.first.id, 'l-1');

      // Redo addition of l2
      await notifier.redo();
      state = container.read(canvasNotifierProvider(initialProject));
      expect(state.project.layers.length, 2);
      expect(state.project.layers.last.id, 'l-2');
    });
  });
}
