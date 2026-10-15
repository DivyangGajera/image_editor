import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/application/canvas_notifier.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/images/presentation/widgets/image_editing_toolbar.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('ImageEditingToolbar', () {
    late Directory tempDir;
    late Box<ProjectModel> testBox;
    late Box<List<dynamic>> historyBox;
    late HistoryManager historyManager;
    late ProjectRepository projectRepository;
    late ProjectModel testProject;
    late ImageLayer testLayer;
    ProviderContainer? testContainer;

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ImageLayerAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TextLayerAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DoodleLayerAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(StickerLayerAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ProjectModelAdapter());
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('image_toolbar_test_');
      Hive.init(tempDir.path);
      testBox = await Hive.openBox<ProjectModel>(StorageKeys.projectsBox);

      testLayer = const ImageLayer(
        id: 'img-1',
        x: 0.5,
        y: 0.5,
        relativeImagePath: 'projects/p1/images/img1.png',
        isFlippedHorizontally: false,
        activeFilter: null,
      );

      testProject = ProjectModel(
        id: 'proj-1',
        title: 'Image Test Project',
        canvasWidth: 1080,
        canvasHeight: 1080,
        createdAt: DateTime(2026, 10, 15),
        updatedAt: DateTime(2026, 10, 15),
        layers: [testLayer],
      );

      historyBox = await Hive.openBox<List<dynamic>>('history_${testProject.id}');
      historyManager = HistoryManager(
        projectId: testProject.id,
        historyBox: historyBox,
      );

      projectRepository = ProjectRepository(
        getBaseDir: () async => tempDir,
        projectsBox: testBox,
      );
    });

    tearDown(() async {
      testContainer?.dispose();
      testContainer = null;
      await historyManager.dispose();
      if (testBox.isOpen) {
        await testBox.close();
      }
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    Widget buildTestableWidget({
      required ImageLayer layer,
      ValueChanged<ImageLayer>? onLayerChanged,
    }) {
      testContainer = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(testProject.id).overrideWithValue(historyManager),
        ],
      );

      return UncontrolledProviderScope(
        container: testContainer!,
        child: MaterialApp(
          home: Scaffold(
            body: ImageEditingToolbar(
              layer: layer,
              project: testProject,
              onLayerChanged: onLayerChanged,
            ),
          ),
        ),
      );
    }

    testWidgets('renders filter chips and flip horizontal button', (tester) async {
      await tester.pumpWidget(buildTestableWidget(layer: testLayer));
      await tester.pumpAndSettle();

      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Grayscale'), findsOneWidget);
      expect(find.text('Warm'), findsOneWidget);
      expect(find.text('Cool'), findsOneWidget);
      expect(find.text('High Contrast'), findsOneWidget);
      expect(find.text('Flip Horizontally'), findsOneWidget);
      expect(find.byKey(const ValueKey('flip_horizontal_button')), findsOneWidget);
    });

    testWidgets('tapping Grayscale filter updates activeFilter in CanvasNotifier', (tester) async {
      ImageLayer? updatedLayer;

      await tester.pumpWidget(
        buildTestableWidget(
          layer: testLayer,
          onLayerChanged: (l) => updatedLayer = l,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Grayscale filter chip
      await tester.runAsync(() async {
        await tester.tap(find.text('Grayscale'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(updatedLayer, isNotNull);
      expect(updatedLayer!.activeFilter, equals('grayscale'));

      final canvasState = testContainer!.read(canvasNotifierProvider(testProject));
      final currentLayer = canvasState.project.layers.first as ImageLayer;
      expect(currentLayer.activeFilter, equals('grayscale'));
    });

    testWidgets('tapping Normal filter resets activeFilter to null', (tester) async {
      ImageLayer? updatedLayer;
      const initialWithFilter = ImageLayer(
        id: 'img-1',
        x: 0.5,
        y: 0.5,
        relativeImagePath: 'projects/p1/images/img1.png',
        activeFilter: 'warm',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          layer: initialWithFilter,
          onLayerChanged: (l) => updatedLayer = l,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Normal filter chip
      await tester.runAsync(() async {
        await tester.tap(find.text('Normal'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(updatedLayer, isNotNull);
      expect(updatedLayer!.activeFilter, isNull);

      final canvasState = testContainer!.read(canvasNotifierProvider(testProject));
      final currentLayer = canvasState.project.layers.first as ImageLayer;
      expect(currentLayer.activeFilter, isNull);
    });

    testWidgets('tapping Flip Horizontally toggles isFlippedHorizontally', (tester) async {
      ImageLayer? updatedLayer;

      await tester.pumpWidget(
        buildTestableWidget(
          layer: testLayer,
          onLayerChanged: (l) => updatedLayer = l,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Flip button
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('flip_horizontal_button')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(updatedLayer, isNotNull);
      expect(updatedLayer!.isFlippedHorizontally, isTrue);

      final canvasState = testContainer!.read(canvasNotifierProvider(testProject));
      final currentLayer = canvasState.project.layers.first as ImageLayer;
      expect(currentLayer.isFlippedHorizontally, isTrue);
    });
  });
}
