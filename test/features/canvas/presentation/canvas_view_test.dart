import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('CanvasView & TransformableBox Widget Tests', () {
    late Directory tempDir;
    late Box<ProjectModel> projectsBox;
    late Box<List<dynamic>> historyBox;
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

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ImageLayerAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TextLayerAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DoodleLayerAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(StickerLayerAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ProjectModelAdapter());
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('canvas_view_test_');
      Hive.init(tempDir.path);
      projectsBox = await Hive.openBox<ProjectModel>(StorageKeys.projectsBox);
      historyBox = await Hive.openBox<List<dynamic>>('history_${project.id}');

      projectRepository = ProjectRepository(
        getBaseDir: () async => tempDir,
        projectsBox: projectsBox,
      );

      historyManager = HistoryManager(
        projectId: project.id,
        historyBox: historyBox,
      );
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
              child: CanvasView(project: project),
            ),
          ),
        ),
      );
    }

    testWidgets('renders all initial layers on the canvas', (tester) async {
      final container = ProviderContainer(
        overrides: <Override>[
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
        overrides: <Override>[
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
      expect(container.read(canvasNotifierProvider(project)).selectedLayerId, 'layer-1');

      // Delete handle and corner anchors appear
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping delete button removes the selected layer', (tester) async {
      final container = ProviderContainer(
        overrides: <Override>[
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
      expect(container.read(canvasNotifierProvider(project)).project.layers.length, 1);
    });

    testWidgets('tapping canvas background deselects active layer', (tester) async {
      final container = ProviderContainer(
        overrides: <Override>[
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
      expect(container.read(canvasNotifierProvider(project)).selectedLayerId, isNull);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('dragging selected layer updates coordinates via gesture input', (tester) async {
      final container = ProviderContainer(
        overrides: <Override>[
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(project.id).overrideWithValue(historyManager),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      final initialX = container.read(canvasNotifierProvider(project)).project.layers.first.x;
      final initialY = container.read(canvasNotifierProvider(project)).project.layers.first.y;

      // Tap to select layer 1
      await tester.tap(find.text('Title Heading'));
      await tester.pumpAndSettle();

      // Drag layer by 150px right and 150px down within runAsync to handle Hive async persistence
      await tester.runAsync(() async {
        await tester.drag(find.text('Title Heading'), const Offset(150.0, 150.0));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      final updatedLayer = container.read(canvasNotifierProvider(project)).project.layers.first;
      expect(updatedLayer.x, isNot(equals(initialX)));
      expect(updatedLayer.y, isNot(equals(initialY)));
      expect(updatedLayer.x, greaterThan(initialX));
      expect(updatedLayer.y, greaterThan(initialY));
    });

    testWidgets('renders properly without RenderFlex overflow on compact viewports', (tester) async {
      final container = ProviderContainer(
        overrides: <Override>[
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
