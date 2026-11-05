import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('CanvasNotifier', () {
    late Directory tempDir;
    late Box<ProjectModel> projectsBox;
    late LazyBox<dynamic> historyBox;
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

    final canvasUnderTest = canvasProvider(initialProject.id);

    setUpAll(AppBootstrap.registerAdapters);

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('canvas_notifier_test_');
      Hive.init(tempDir.path);
      projectsBox = await Hive.openBox<ProjectModel>(StorageKeys.projectsBox);
      historyBox = await Hive.openLazyBox<dynamic>('history_${initialProject.id}');

      projectRepository = ProjectRepository(
        getBaseDir: () async => tempDir,
        projectsBox: projectsBox,
      );

      historyManager = HistoryManager(
        projectId: initialProject.id,
        historyBox: historyBox,
      );

      await projectRepository.saveProject(initialProject);

      container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(initialProject.id).overrideWithValue(historyManager),
        ],
      );

      // Keep the auto-disposed canvas provider alive and wait for the project to load.
      container.listen(canvasUnderTest, (_, _) {});
      await container.read(canvasUnderTest.future);
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

    CanvasState readState() => container.read(canvasUnderTest).requireValue;

    TextLayer makeText(String id, String text) {
      return TextLayer(id: id, x: 0.5, y: 0.5, text: text);
    }

    test('loads the project from the repository into initial state', () {
      final state = readState();

      expect(state.project.id, initialProject.id);
      expect(state.project.layers, isEmpty);
      expect(state.selectedLayerId, isNull);
      expect(state.selectedLayer, isNull);
      expect(state.isInteracting, isFalse);
    });

    test('selectLayer updates ephemeral state without modifying history', () {
      final notifier = container.read(canvasUnderTest.notifier);

      notifier.selectLayer('l-test-1');
      expect(readState().selectedLayerId, 'l-test-1');

      final history = container.read(historyProvider(initialProject.id));
      expect(history.canUndo, isFalse);
    });

    group('gesture interaction', () {
      test('preview updates state live without history or persistence', () async {
        final notifier = container.read(canvasUnderTest.notifier);
        await notifier.addLayer(makeText('l-1', 'Drag me'));
        final undoBefore = container.read(historyProvider(initialProject.id)).totalUndoCount;

        notifier.beginInteraction('l-1');
        expect(readState().isInteracting, isTrue);
        expect(readState().selectedLayerId, 'l-1');

        for (var i = 1; i <= 30; i++) {
          notifier.previewTransform('l-1', x: 0.5 + i * 0.01, rotation: i * 0.01);
        }

        expect(readState().project.layers.single.x, closeTo(0.8, 1e-9));
        expect(
          container.read(historyProvider(initialProject.id)).totalUndoCount,
          undoBefore,
          reason: 'no history entry per frame',
        );
        final persisted = await projectRepository.loadProject(initialProject.id);
        expect(persisted!.layers.single.x, 0.5, reason: 'no disk write per frame');
      });

      test('commit records exactly one undo step and persists once', () async {
        final notifier = container.read(canvasUnderTest.notifier);
        await notifier.addLayer(makeText('l-1', 'Drag me'));
        final undoBefore = container.read(historyProvider(initialProject.id)).totalUndoCount;

        notifier.beginInteraction('l-1');
        notifier.previewTransform('l-1', x: 0.6, y: 0.4);
        notifier.previewTransform('l-1', x: 0.7, y: 0.3, scale: 2.0);
        await notifier.commitInteraction();

        expect(readState().isInteracting, isFalse);
        expect(
          container.read(historyProvider(initialProject.id)).totalUndoCount,
          undoBefore + 1,
        );
        final persisted = await projectRepository.loadProject(initialProject.id);
        expect(persisted!.layers.single.x, 0.7);
        expect(persisted.layers.single.scale, 2.0);

        await notifier.undo();
        final restored = readState().project.layers.single;
        expect(restored.x, 0.5, reason: 'undo returns to the pre-gesture position');
        expect(restored.y, 0.5);
        expect(restored.scale, 1.0);
      });

      test('a gesture that changes nothing records no history', () async {
        final notifier = container.read(canvasUnderTest.notifier);
        await notifier.addLayer(makeText('l-1', 'Tap only'));
        final undoBefore = container.read(historyProvider(initialProject.id)).totalUndoCount;

        notifier.beginInteraction('l-1');
        await notifier.commitInteraction();

        expect(
          container.read(historyProvider(initialProject.id)).totalUndoCount,
          undoBefore,
        );
      });
    });

    test('addLayer appends layer, assigns sequential zIndex, auto-selects, and records history', () async {
      final notifier = container.read(canvasUnderTest.notifier);
      final layer1 = makeText('l-1', 'First');
      final layer2 = makeText('l-2', 'Second');

      await notifier.addLayer(layer1);
      var state = readState();
      expect(state.project.layers.length, 1);
      expect(state.project.layers[0].zIndex, 0);
      expect(state.selectedLayerId, 'l-1');

      await notifier.addLayer(layer2);
      state = readState();
      expect(state.project.layers.length, 2);
      expect(state.project.layers[0].zIndex, 0);
      expect(state.project.layers[1].zIndex, 1);
      expect(state.selectedLayerId, 'l-2');

      final history = container.read(historyProvider(initialProject.id));
      expect(history.canUndo, isTrue);
      expect(history.totalUndoCount, 2);
    });

    test('updateLayerTransform modifies target layer and records history', () async {
      final notifier = container.read(canvasUnderTest.notifier);
      await notifier.addLayer(makeText('l-1', 'Initial'));

      await notifier.updateLayerTransform(
        'l-1',
        x: 0.8,
        y: 0.3,
        scale: 1.5,
        rotation: 0.5,
      );

      final state = readState();
      final updated = state.project.layers.first;
      expect(updated.x, 0.8);
      expect(updated.y, 0.3);
      expect(updated.scale, 1.5);
      expect(updated.rotation, 0.5);

      final history = container.read(historyProvider(initialProject.id));
      expect(history.totalUndoCount, 2);
    });

    test('reorderLayer swaps positions, updates zIndex sequentially, and records history', () async {
      final notifier = container.read(canvasUnderTest.notifier);
      await notifier.addLayer(makeText('l-0', 'Zero'));
      await notifier.addLayer(makeText('l-1', 'One'));
      await notifier.addLayer(makeText('l-2', 'Two'));

      // Move layer at index 0 to index 2
      await notifier.reorderLayer(0, 2);

      final state = readState();
      expect(state.project.layers[0].id, 'l-1');
      expect(state.project.layers[0].zIndex, 0);

      expect(state.project.layers[1].id, 'l-2');
      expect(state.project.layers[1].zIndex, 1);

      expect(state.project.layers[2].id, 'l-0');
      expect(state.project.layers[2].zIndex, 2);
    });

    test('bringToFront and sendToBack update stacking order and zIndex', () async {
      final notifier = container.read(canvasUnderTest.notifier);
      await notifier.addLayer(makeText('l-0', 'Bottom'));
      await notifier.addLayer(makeText('l-1', 'Middle'));
      await notifier.addLayer(makeText('l-2', 'Top'));

      // Bring 'Bottom' to front
      await notifier.bringToFront('l-0');
      var state = readState();
      expect(state.project.layers.last.id, 'l-0');
      expect(state.project.layers.last.zIndex, 2);

      // Send 'Bottom' to back
      await notifier.sendToBack('l-0');
      state = readState();
      expect(state.project.layers.first.id, 'l-0');
      expect(state.project.layers.first.zIndex, 0);
    });

    test('deleteLayer removes layer, clears selection if matching, and re-indexes remaining layers', () async {
      final notifier = container.read(canvasUnderTest.notifier);
      await notifier.addLayer(makeText('l-0', 'Zero'));
      await notifier.addLayer(makeText('l-1', 'One'));
      await notifier.addLayer(makeText('l-2', 'Two'));

      notifier.selectLayer('l-1');
      expect(readState().selectedLayerId, 'l-1');

      await notifier.deleteLayer('l-1');
      final state = readState();

      expect(state.project.layers.length, 2);
      expect(state.project.layers.any((l) => l.id == 'l-1'), isFalse);
      expect(state.selectedLayerId, isNull);

      // Verify re-indexed zIndex values
      expect(state.project.layers[0].id, 'l-0');
      expect(state.project.layers[0].zIndex, 0);
      expect(state.project.layers[1].id, 'l-2');
      expect(state.project.layers[1].zIndex, 1);
    });

    test('duplicateLayer inserts an offset copy directly above and selects it', () async {
      final notifier = container.read(canvasUnderTest.notifier);
      await notifier.addLayer(makeText('l-0', 'Bottom'));
      await notifier.addLayer(makeText('l-1', 'Top'));
      final undoBefore = container.read(historyProvider(initialProject.id)).totalUndoCount;

      final copyId = await notifier.duplicateLayer('l-0');

      final layers = readState().project.layers;
      expect(layers.map((l) => l.id).toList(), <String?>['l-0', copyId, 'l-1']);
      expect(layers.map((l) => l.zIndex).toList(), <int>[0, 1, 2]);
      expect(layers[1], isA<TextLayer>());
      expect((layers[1] as TextLayer).text, 'Bottom');
      expect(layers[1].x, closeTo(0.5 + CanvasNotifier.duplicateOffset, 1e-12));
      expect(readState().selectedLayerId, copyId);
      expect(
        container.read(historyProvider(initialProject.id)).totalUndoCount,
        undoBefore + 1,
      );
    });

    test('toggleVisibility hides and deselects, then shows the layer again', () async {
      final notifier = container.read(canvasUnderTest.notifier);
      await notifier.addLayer(makeText('l-0', 'Toggle'));
      expect(readState().selectedLayerId, 'l-0');

      await notifier.toggleVisibility('l-0');
      expect(readState().project.layers.single.isVisible, isFalse);
      expect(readState().selectedLayerId, isNull);

      await notifier.toggleVisibility('l-0');
      expect(readState().project.layers.single.isVisible, isTrue);

      await notifier.undo();
      expect(readState().project.layers.single.isVisible, isFalse);
    });

    test('toggleLock locks a layer against moving, keeps it selected and can be undone', () async {
      final notifier = container.read(canvasUnderTest.notifier);
      await notifier.addLayer(makeText('l-0', 'Logo'));
      final x = readState().project.layers.single.x;

      await notifier.toggleLock('l-0');
      expect(readState().project.layers.single.isLocked, isTrue);
      expect(readState().selectedLayerId, 'l-0', reason: 'still selected so it can be unlocked');

      notifier.beginInteraction('l-0');
      notifier.previewTransform('l-0', x: x + 0.3, scale: 3.0);
      await notifier.commitInteraction();
      expect(readState().project.layers.single.x, x, reason: 'locked layers never move');
      expect(readState().project.layers.single.scale, 1.0);

      await notifier.undo();
      expect(readState().project.layers.single.isLocked, isFalse);
    });

    test('duplicating a locked layer gives an unlocked copy that can be moved', () async {
      final notifier = container.read(canvasUnderTest.notifier);
      await notifier.addLayer(makeText('l-0', 'Logo'));
      await notifier.toggleLock('l-0');

      final copyId = await notifier.duplicateLayer('l-0');

      final layers = readState().project.layers;
      expect(layers.firstWhere((l) => l.id == 'l-0').isLocked, isTrue);
      expect(layers.firstWhere((l) => l.id == copyId).isLocked, isFalse);
    });

    test('applyCutout hides the source and stacks the cutout on top with its transform',
        () async {
      final notifier = container.read(canvasUnderTest.notifier);
      const source = ImageLayer(
        id: 'photo',
        x: 0.3,
        y: 0.6,
        scale: 0.4,
        rotation: 0.2,
        isFlippedHorizontally: true,
        relativeImagePath: 'projects/p/images/photo.jpg',
      );
      await notifier.addLayer(source);
      await notifier.addLayer(makeText('caption', 'On top'));
      final undoBefore = container.read(historyProvider(initialProject.id)).totalUndoCount;

      await notifier.applyCutout(
        'photo',
        const ImageLayer(
          id: 'cutout',
          x: 0.5,
          y: 0.5,
          relativeImagePath: 'projects/p/images/cutout.png',
        ),
      );

      final layers = readState().project.layers;
      expect(layers.map((l) => l.id).toList(), <String>['photo', 'cutout', 'caption']);
      expect(layers[0].isVisible, isFalse);
      final cutout = layers[1] as ImageLayer;
      expect(cutout.x, 0.3);
      expect(cutout.y, 0.6);
      expect(cutout.scale, 0.4);
      expect(cutout.rotation, 0.2);
      expect(cutout.isFlippedHorizontally, isTrue);
      expect(readState().selectedLayerId, 'cutout');
      expect(
        container.read(historyProvider(initialProject.id)).totalUndoCount,
        undoBefore + 1,
      );

      await notifier.undo();
      expect(readState().project.layers.map((l) => l.id), <String>['photo', 'caption']);
      expect(readState().project.layers.first.isVisible, isTrue);
    });

    test('rapid edits fired without awaiting all apply and each records history', () async {
      final notifier = container.read(canvasUnderTest.notifier);

      await Future.wait([
        notifier.addLayer(makeText('a', 'A')),
        notifier.addLayer(makeText('b', 'B')),
        notifier.addLayer(makeText('c', 'C')),
      ]);

      expect(readState().project.layers.map((l) => l.id), ['a', 'b', 'c']);
      expect(container.read(historyProvider(initialProject.id)).totalUndoCount, 3);
      final persisted = await projectRepository.loadProject(initialProject.id);
      expect(persisted!.layers, hasLength(3));
    });

    test('an edit is still saved if the editor closes while history is writing', () async {
      // A dedicated container that is torn down mid-edit, as when the editor
      // screen closes and its auto-disposed providers go away.
      final editor = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(initialProject.id).overrideWithValue(historyManager),
        ],
      );
      editor.listen(canvasUnderTest, (_, _) {});
      await editor.read(canvasUnderTest.future);

      final pending = editor.read(canvasUnderTest.notifier).addLayer(makeText('late', 'Saved'));
      editor.dispose();

      await expectLater(pending, completes);
      final persisted = await projectRepository.loadProject(initialProject.id);
      expect(persisted!.layers.single.id, 'late');
    });

    test('renameProject trims, persists and ignores blank titles', () async {
      final notifier = container.read(canvasUnderTest.notifier);

      await notifier.renameProject('  Diwali Sale  ');
      expect(readState().project.title, 'Diwali Sale');
      expect((await projectRepository.loadProject(initialProject.id))!.title, 'Diwali Sale');

      await notifier.renameProject('   ');
      expect(readState().project.title, 'Diwali Sale');
    });

    test('setBackgroundColor persists and is undoable together with layers', () async {
      final notifier = container.read(canvasUnderTest.notifier);
      await notifier.addLayer(makeText('l-1', 'Sale'));

      await notifier.setBackgroundColor(0xFFFACC15);
      expect(readState().project.backgroundColorValue, 0xFFFACC15);
      expect((await projectRepository.loadProject(initialProject.id))!.backgroundColorValue,
          0xFFFACC15);

      await notifier.undo();
      expect(readState().project.backgroundColorValue, ProjectModel.defaultBackgroundColor);
      expect(readState().project.layers, hasLength(1), reason: 'layers are untouched');

      await notifier.redo();
      expect(readState().project.backgroundColorValue, 0xFFFACC15);
    });

    test('undo and redo revert and re-apply canvas layer states', () async {
      final notifier = container.read(canvasUnderTest.notifier);
      final l1 = makeText('l-1', 'First');
      final l2 = makeText('l-2', 'Second');

      await notifier.addLayer(l1);
      await notifier.addLayer(l2);

      expect(readState().project.layers.length, 2);

      // Undo addition of l2
      await notifier.undo();
      var state = readState();
      expect(state.project.layers.length, 1);
      expect(state.project.layers.first.id, 'l-1');

      // Undo addition of l1
      await notifier.undo();
      state = readState();
      expect(state.project.layers, isEmpty);

      // Redo addition of l1
      await notifier.redo();
      state = readState();
      expect(state.project.layers.length, 1);
      expect(state.project.layers.first.id, 'l-1');

      // Redo addition of l2
      await notifier.redo();
      state = readState();
      expect(state.project.layers.length, 2);
      expect(state.project.layers.last.id, 'l-2');
    });

    test('build fails with StateError and creates no history for a missing project', () async {
      final missing = canvasProvider('missing-project');
      container.listen(missing, (_, _) {});

      await expectLater(
        container.read(missing.future),
        throwsA(isA<StateError>()),
      );
      expect(
        Hive.isBoxOpen(HistoryManager.boxNameFor('missing-project')),
        isFalse,
        reason: 'no history box may be created for a project that does not exist',
      );
    });
  });
}
