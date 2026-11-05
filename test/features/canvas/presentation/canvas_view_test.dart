import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

import '../../../helpers/pump_until.dart';

void main() {
  group('CanvasView & TransformableBox Widget Tests', () {
    late Directory tempDir;
    late Box<ProjectModel> projectsBox;
    late LazyBox<dynamic> historyBox;
    late ProjectRepository projectRepository;
    late HistoryManager historyManager;
    final testDate = DateTime(2026, 10, 15, 14, 0);

    const layer1 = TextLayer(
      id: 'layer-1',
      x: 0.5,
      y: 0.3,
      text: 'Title Heading',
      zIndex: 0,
    );

    const layer2 = TextLayer(
      id: 'layer-2',
      x: 0.5,
      y: 0.7,
      text: 'Subtitle Content',
      zIndex: 1,
    );

    final project = ProjectModel(
      id: 'proj-widget-test',
      title: 'Widget Test Artwork',
      canvasWidth: 1000.0,
      canvasHeight: 1000.0,
      layers: const <CanvasLayer>[layer1, layer2],
      createdAt: testDate,
      updatedAt: testDate,
    );

    setUpAll(AppBootstrap.registerAdapters);

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('canvas_view_test_');
      Hive.init(tempDir.path);
      projectsBox = await Hive.openBox<ProjectModel>(StorageKeys.projectsBox);
      historyBox = await Hive.openLazyBox<dynamic>('history_${project.id}');

      projectRepository = ProjectRepository(
        getBaseDir: () async => tempDir,
        projectsBox: projectsBox,
      );

      historyManager = HistoryManager(
        projectId: project.id,
        historyBox: historyBox,
      );

      // Read persisted history up front: real Hive I/O cannot complete inside

      // the fake-async zone that widget tests run in.

      await historyManager.load();

      await projectRepository.saveProject(project);
    });

    tearDown(() async {
      await historyManager.dispose();
      await projectsBox.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    Widget createTestApp(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800.0,
              height: 800.0,
              child: Consumer(
                builder: (context, ref, _) {
                  final loaded = ref.watch(canvasProvider(project.id)).hasValue;
                  return loaded
                      ? CanvasView(projectId: project.id)
                      : const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders all initial layers on the canvas', (tester) async {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(project.id).overrideWithValue(historyManager),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      expect(find.text('Title Heading'), findsOneWidget);
      expect(find.text('Subtitle Content'), findsOneWidget);
    });

    testWidgets('tapping a layer selects it and displays bounding box and delete handle', (tester) async {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(project.id).overrideWithValue(historyManager),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Initially no delete button or handles
      expect(find.byIcon(Icons.close), findsNothing);

      // Tap on layer 1
      await tester.tap(find.text('Title Heading'));
      await tester.pumpAndSettle();

      // State is selected
      expect(container.read(canvasProvider(project.id)).requireValue.selectedLayerId, 'layer-1');

      // Delete handle and corner anchors appear
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping delete button removes the selected layer', (tester) async {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(project.id).overrideWithValue(historyManager),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Select layer 1
      await tester.tap(find.text('Title Heading'));
      await tester.pumpAndSettle();

      // Tap delete button within runAsync to let Hive file I/O complete
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.close));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Layer 1 is removed, layer 2 remains
      expect(find.text('Title Heading'), findsNothing);
      expect(find.text('Subtitle Content'), findsOneWidget);
      expect(container.read(canvasProvider(project.id)).requireValue.project.layers.length, 1);
    });

    testWidgets('tapping canvas background deselects active layer', (tester) async {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(project.id).overrideWithValue(historyManager),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Select layer 1
      await tester.tap(find.text('Title Heading'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Tap empty canvas background area (top-left corner)
      await tester.tapAt(const Offset(50.0, 50.0));
      await tester.pumpAndSettle();

      // Selection cleared and handles dismissed
      expect(container.read(canvasProvider(project.id)).requireValue.selectedLayerId, isNull);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('dragging a layer tracks the finger exactly and is one undo step', (tester) async {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(project.id).overrideWithValue(historyManager),
        ],
      );
      addTearDown(container.dispose);

      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      double layerX() =>
          container.read(canvasProvider(project.id)).requireValue.project.layers.first.x;
      double layerY() =>
          container.read(canvasProvider(project.id)).requireValue.project.layers.first.y;

      // Canvas 1000x1000 inside an 800x800 viewport -> 0.8 screen px per canvas unit.
      final gesture = await tester.startGesture(tester.getCenter(find.text('Title Heading')));
      // First move passes the touch slop and starts the gesture.
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      final xAfterStart = layerX();
      final yAfterStart = layerY();

      await gesture.moveBy(const Offset(80, 40));
      await tester.pump();

      // 80 px on screen = 100 canvas units = 0.1 of the 1000-unit canvas.
      expect(layerX() - xAfterStart, closeTo(0.1, 1e-6));
      expect(layerY() - yAfterStart, closeTo(0.05, 1e-6));

      await tester.runAsync(() async {
        await gesture.up();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      await pumpUntil(
        tester,
        () => container.read(historyProvider(project.id)).totalUndoCount == 1,
      );

      await tester.runAsync(() => container.read(canvasProvider(project.id).notifier).undo());
      await tester.pumpAndSettle();
      expect(layerX(), 0.5, reason: 'undo restores the pre-drag position');
      expect(layerY(), 0.3);
    });

    testWidgets('a locked layer can be selected but not dragged, and shows a lock badge', (tester) async {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(project.id).overrideWithValue(historyManager),
        ],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();
      final notifier = container.read(canvasProvider(project.id).notifier);
      final firstId = notifier.currentState.project.layers.first.id;
      await tester.runAsync(() => notifier.toggleLock(firstId));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Title Heading'));
      await tester.pumpAndSettle();
      expect(container.read(canvasProvider(project.id)).requireValue.selectedLayerId, firstId);
      expect(find.byKey(const ValueKey('locked_badge')), findsOneWidget);
      expect(find.byKey(const ValueKey('rotate_scale_handle')), findsNothing);
      expect(find.bySemanticsLabel('Delete Layer'), findsNothing);

      await tester.drag(find.text('Title Heading'), const Offset(120, 60));
      await tester.pumpAndSettle();
      final layer = container.read(canvasProvider(project.id)).requireValue.project.layers.first;
      expect(layer.x, 0.5);
      expect(layer.y, 0.3);
    });

    testWidgets('hidden layers are not rendered', (tester) async {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(project.id).overrideWithValue(historyManager),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();
      expect(find.text('Subtitle Content'), findsOneWidget);

      await tester.runAsync(
        () => container.read(canvasProvider(project.id).notifier).toggleVisibility('layer-2'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subtitle Content'), findsNothing);
      expect(find.text('Title Heading'), findsOneWidget);
    });

    testWidgets('renders properly without RenderFlex overflow on compact viewports', (tester) async {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(project.id).overrideWithValue(historyManager),
        ],
      );
      addTearDown(container.dispose);

      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Title Heading'), findsOneWidget);
    });
  });
}
