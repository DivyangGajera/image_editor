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
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/stickers/presentation/widgets/sticker_picker_sheet.dart';

void main() {
  group('StickerPickerSheet', () {
    late Directory tempDir;
    late Box<ProjectModel> testBox;
    late LazyBox<List<dynamic>> historyBox;
    late HistoryManager historyManager;
    late ProjectRepository projectRepository;
    late ProjectModel testProject;
    ProviderContainer? testContainer;

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ImageLayerAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TextLayerAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DoodleLayerAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(StickerLayerAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ProjectModelAdapter());
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sticker_picker_test_');
      Hive.init(tempDir.path);
      testBox = await Hive.openBox<ProjectModel>(StorageKeys.projectsBox);

      testProject = ProjectModel(
        id: 'test-proj',
        title: 'Test Project',
        canvasWidth: 1080,
        canvasHeight: 1080,
        createdAt: DateTime(2026, 10, 15),
        updatedAt: DateTime(2026, 10, 15),
        layers: const [],
      );

      historyBox = await Hive.openLazyBox<List<dynamic>>('history_${testProject.id}');
      historyManager = HistoryManager(
        projectId: testProject.id,
        historyBox: historyBox,
      );
      // Read persisted history up front: real Hive I/O cannot complete inside
      // the fake-async zone that widget tests run in.
      await historyManager.load();

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
      StickerLayer? Function(StickerLayer)? onSelected,
      String? projectId,
    }) {
      return ProviderScope(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(testProject.id).overrideWithValue(historyManager),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StickerPickerSheet(
              projectId: projectId,
              onStickerSelected: onSelected != null ? (layer) => onSelected(layer) : null,
            ),
          ),
        ),
      );
    }

    testWidgets('renders category tabs and title correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Stickers & Badges'), findsOneWidget);
      expect(find.text('Discounts'), findsOneWidget);
      expect(find.text('Urgency'), findsOneWidget);
      expect(find.text('Badges'), findsOneWidget);

      // Verify thumbnails are displayed for initial tab (Discounts)
      expect(find.text('50% OFF'), findsOneWidget);
      expect(find.text('BUY 1 GET 1'), findsOneWidget);
      expect(find.text('SPECIAL OFFER'), findsOneWidget);
    });

    testWidgets('switching tabs reveals relevant stickers', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap 'Urgency' tab
      await tester.tap(find.text('Urgency'));
      await tester.pumpAndSettle();

      expect(find.text('LIMITED TIME'), findsOneWidget);
      expect(find.text('SALE ENDS TODAY'), findsOneWidget);
      expect(find.text('LAST CHANCE'), findsOneWidget);

      // Tap 'Badges' tab
      await tester.tap(find.text('Badges'));
      await tester.pumpAndSettle();

      expect(find.text('BESTSELLER'), findsOneWidget);
      expect(find.text('NEW ARRIVAL'), findsOneWidget);
      expect(find.text('PREMIUM QUALITY'), findsOneWidget);
    });

    testWidgets('selecting a sticker instantiates StickerLayer and triggers callback', (tester) async {
      StickerLayer? selectedLayer;

      await tester.pumpWidget(
        buildTestableWidget(
          onSelected: (layer) {
            selectedLayer = layer;
            return layer;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap '50% OFF' sticker thumbnail
      await tester.tap(find.text('50% OFF'));
      await tester.pumpAndSettle();

      expect(selectedLayer, isNotNull);
      expect(selectedLayer!.assetPath, equals('assets/stickers/discounts/discount_50_off.png'));
      expect(selectedLayer!.x, equals(0.5));
      expect(selectedLayer!.y, equals(0.5));
      expect(selectedLayer!.scale, equals(1.0));
      expect(selectedLayer!.rotation, equals(0.0));
      expect(selectedLayer!.isVisible, isTrue);
      expect(selectedLayer!.id, isNotEmpty);
    });

    testWidgets('StickerPickerSheet.show opens modal bottom sheet and returns selected layer', (tester) async {
      StickerLayer? result;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await StickerPickerSheet.show(context);
                  },
                  child: const Text('Open Picker'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.byType(StickerPickerSheet), findsOneWidget);

      // Tap sticker
      await tester.tap(find.text('BUY 1 GET 1'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed and result returned
      expect(find.byType(StickerPickerSheet), findsNothing);
      expect(result, isNotNull);
      expect(result!.assetPath, equals('assets/stickers/discounts/discount_bogo.png'));
    });

    testWidgets('selecting sticker with active project adds layer to CanvasNotifier', (tester) async {
      testContainer = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
          historyManagerProvider(testProject.id).overrideWithValue(historyManager),
        ],
      );
      final container = testContainer!;
      // Real Hive file I/O must run outside the fake-async test zone.
      await tester.runAsync(() => projectRepository.saveProject(testProject));
      container.listen(canvasProvider(testProject.id), (_, _) {});

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: StickerPickerSheet(
                projectId: testProject.id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(canvasProvider(testProject.id)).requireValue.project.layers, isEmpty);

      // Tap sticker within runAsync to let Hive file I/O complete
      await tester.runAsync(() async {
        await tester.tap(find.text('SPECIAL OFFER'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      final state = container.read(canvasProvider(testProject.id)).requireValue;
      expect(state.project.layers.length, equals(1));
      expect(state.project.layers.first, isA<StickerLayer>());
      final layer = state.project.layers.first as StickerLayer;
      expect(layer.assetPath, equals('assets/stickers/discounts/discount_special_offer.png'));
      expect(state.selectedLayerId, equals(layer.id));
    });
  });
}
