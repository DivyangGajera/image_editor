import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/editor/editor.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  late Directory tempDir;
  late ProjectRepository repository;
  late HistoryManager historyManager;
  late ProviderContainer container;

  const projectId = 'editor-screen';

  setUpAll(() {
    AppBootstrap.registerAdapters();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> createProject(List<CanvasLayer> layers) async {
    tempDir = await Directory.systemTemp.createTemp('editor_screen_test_');
    Hive.init(tempDir.path);
    repository = ProjectRepository(
      getBaseDir: () async => tempDir,
      projectsBox: await Hive.openBox<ProjectModel>(StorageKeys.projectsBox),
    );
    await repository.saveProject(
      ProjectModel(
        id: projectId,
        title: 'Summer Sale',
        canvasWidth: 1080.0,
        canvasHeight: 1080.0,
        layers: layers,
        createdAt: DateTime(2026, 11, 4),
        updatedAt: DateTime(2026, 11, 4),
      ),
    );
    historyManager = HistoryManager(
      projectId: projectId,
      historyBox: await Hive.openLazyBox<List<dynamic>>(HistoryManager.boxNameFor(projectId)),
    );
    // Real Hive I/O cannot complete inside the widget-test fake-async zone.
    await historyManager.load();
    container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        historyManagerProvider(projectId).overrideWithValue(historyManager),
      ],
    );
  }

  tearDown(() async {
    container.dispose();
    await historyManager.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<void> pumpEditor(WidgetTester tester, {String id = projectId}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light(), home: EditorScreen(projectId: id)),
      ),
    );
    await tester.pumpAndSettle();
  }

  CanvasState canvas() => container.read(canvasProvider(projectId)).requireValue;

  /// Runs a canvas mutation (real Hive writes) outside the fake-async zone.
  Future<void> mutate(WidgetTester tester, Future<void> Function() action) async {
    await tester.runAsync(action);
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(finder);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  const photo = ImageLayer(
    id: 'photo',
    x: 0.5,
    y: 0.5,
    relativeImagePath: 'projects/editor-screen/images/photo.jpg',
  );
  const caption = TextLayer(id: 'caption', x: 0.5, y: 0.2, zIndex: 1, text: 'Big Sale');

  testWidgets('shows the title and the add-content tools with undo disabled', (tester) async {
    await tester.runAsync(() => createProject(const []));
    await pumpEditor(tester);

    expect(find.text('Summer Sale'), findsOneWidget);
    expect(find.byKey(const ValueKey('main_bar')), findsOneWidget);
    for (final label in ['Photo', 'Text', 'Sticker', 'Draw']) {
      expect(find.text(label), findsOneWidget);
    }
    final undo = tester.widget<IconButton>(find.byKey(const ValueKey('editor_undo')));
    expect(undo.onPressed, isNull);
  });

  testWidgets('shows an error page for a project that does not exist', (tester) async {
    await tester.runAsync(() => createProject(const []));
    await pumpEditor(tester, id: 'missing');

    expect(find.text('This project could not be found.'), findsOneWidget);
  });

  testWidgets('selecting an image shows image actions; flip and filters update the layer',
      (tester) async {
    await tester.runAsync(() => createProject(const [photo, caption]));
    await pumpEditor(tester);

    container.read(canvasProvider(projectId).notifier).selectLayer('photo');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ctx_flip')), findsOneWidget);
    expect(find.byKey(const ValueKey('ctx_remove_bg')), findsOneWidget);
    expect(find.byKey(const ValueKey('ctx_edit_text')), findsNothing);

    await tapAndSettle(tester, find.byKey(const ValueKey('ctx_flip')));
    expect((canvas().project.layers.first as ImageLayer).isFlippedHorizontally, isTrue);

    await tapAndSettle(tester, find.byKey(const ValueKey('ctx_filters')));
    await tapAndSettle(tester, find.byKey(const ValueKey('filter_chip_grayscale')));
    expect((canvas().project.layers.first as ImageLayer).activeFilter, 'grayscale');

    // Undo is now available and reverts the filter.
    final undo = tester.widget<IconButton>(find.byKey(const ValueKey('editor_undo')));
    expect(undo.onPressed, isNotNull);
    await tapAndSettle(tester, find.byKey(const ValueKey('editor_undo')));
    expect((canvas().project.layers.first as ImageLayer).activeFilter, isNull);
  });

  testWidgets('text layers offer Edit; duplicate and delete work from the context bar',
      (tester) async {
    await tester.runAsync(() => createProject(const [photo, caption]));
    await pumpEditor(tester);

    container.read(canvasProvider(projectId).notifier).selectLayer('caption');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ctx_edit_text')), findsOneWidget);
    expect(find.byKey(const ValueKey('ctx_flip')), findsNothing);

    await tapAndSettle(tester, find.byKey(const ValueKey('ctx_duplicate')));
    expect(canvas().project.layers, hasLength(3));

    await tapAndSettle(tester, find.byKey(const ValueKey('ctx_delete')));
    expect(canvas().project.layers, hasLength(2));
    expect(find.byKey(const ValueKey('main_bar')), findsOneWidget);
  });

  testWidgets('draw mode turns strokes into doodle layers and Done returns to the tools',
      (tester) async {
    await tester.runAsync(() => createProject(const []));
    await pumpEditor(tester);

    await tapAndSettle(tester, find.byKey(const ValueKey('tool_draw')));
    expect(find.byKey(const ValueKey('draw_bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('doodle_overlay')), findsOneWidget);

    await tester.runAsync(() async {
      final center = tester.getCenter(find.byKey(const ValueKey('doodle_overlay')));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(40, 10));
      await gesture.moveBy(const Offset(40, 30));
      await gesture.up();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(canvas().project.layers.single, isA<DoodleLayer>());

    await tapAndSettle(tester, find.byKey(const ValueKey('draw_done')));
    expect(find.byKey(const ValueKey('main_bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('doodle_overlay')), findsNothing);
  });

  testWidgets('layers sheet lists layers top first and toggles visibility', (tester) async {
    await tester.runAsync(() => createProject(const [photo, caption]));
    await pumpEditor(tester);

    await tapAndSettle(tester, find.byKey(const ValueKey('editor_layers')));

    final rows = find.byWidgetPredicate(
      (w) => w is ListTile && w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('layer_row_'),
    );
    final keys = tester.widgetList<ListTile>(rows).map((t) => (t.key! as ValueKey<String>).value);
    expect(keys, <String>['layer_row_caption', 'layer_row_photo']);
    expect(find.text('Big Sale'), findsWidgets);

    await tapAndSettle(tester, find.byKey(const ValueKey('layer_visibility_photo')));
    expect(canvas().project.layers.first.isVisible, isFalse);
  });

  test('row moves map onto bottom-first layer indices', () {
    // 3 layers, rows top-first: row 0 = layer 2. Moving the top row to the
    // bottom row sends layer 2 to index 0.
    expect(LayersSheet.layerIndicesForRowMove(oldRow: 0, newRow: 2, layerCount: 3), (2, 0));
    expect(LayersSheet.layerIndicesForRowMove(oldRow: 2, newRow: 0, layerCount: 3), (0, 2));
    expect(LayersSheet.layerIndicesForRowMove(oldRow: 1, newRow: 1, layerCount: 3), (1, 1));
  });

  testWidgets('reordering rows in the layers sheet restacks the canvas', (tester) async {
    await tester.runAsync(() => createProject(const [photo, caption]));
    await pumpEditor(tester);
    await tapAndSettle(tester, find.byKey(const ValueKey('editor_layers')));

    final list = tester.widget<ReorderableListView>(find.byType(ReorderableListView));
    // Move the top row (caption) to the bottom.
    await tester.runAsync(() async {
      list.onReorderItem!(0, 1);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(canvas().project.layers.map((l) => l.id), <String>['caption', 'photo']);
  });

  testWidgets('canvas mutations from outside are reflected in the bars', (tester) async {
    await tester.runAsync(() => createProject(const [photo]));
    await pumpEditor(tester);

    await mutate(tester, () => container.read(canvasProvider(projectId).notifier).duplicateLayer('photo'));

    // The copy is selected, so the image context bar is shown.
    expect(find.byKey(const ValueKey('ctx_remove_bg')), findsOneWidget);
  });
}
