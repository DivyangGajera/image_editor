import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/editor/editor.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/core/network/internet_check.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/segmentation/application/subject_model_installer.dart';

import 'package:image_editor/features/tutorial/tutorial.dart';

import '../../../helpers/fake_internet_check.dart';
import '../../../helpers/memory_tutorial_repository.dart';
import '../../../helpers/fake_subject_model_installer.dart';
import '../../../helpers/pump_until.dart';

void main() {
  late Directory tempDir;
  late ProjectRepository repository;
  late HistoryManager historyManager;
  late ProviderContainer container;
  late FakeSubjectModelInstaller installer;
  late MemoryTutorialRepository tutorial;

  const projectId = 'editor-screen';

  setUpAll(AppBootstrap.registerAdapters);

  Future<void> createProject(List<CanvasLayer> layers, {bool toursUnseen = false}) async {
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
      historyBox: await Hive.openLazyBox<dynamic>(HistoryManager.boxNameFor(projectId)),
    );
    // Real Hive I/O cannot complete inside the widget-test fake-async zone.
    await historyManager.load();
    installer = FakeSubjectModelInstaller();
    tutorial = toursUnseen ? MemoryTutorialRepository.unseen() : MemoryTutorialRepository();
    container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        historyManagerProvider(projectId).overrideWithValue(historyManager),
        subjectModelInstallerProvider.overrideWithValue(installer),
        internetCheckProvider.overrideWithValue(FakeInternetCheck()),
        tutorialRepositoryProvider.overrideWithValue(tutorial),
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
    expect(find.byKey(const ValueKey('empty_canvas_hint')), findsOneWidget);
    for (final label in ['Photo', 'Text', 'Sticker', 'Draw']) {
      expect(find.text(label), findsOneWidget);
    }
    final undo = tester.widget<ToolButton>(find.byKey(const ValueKey('editor_undo')));
    expect(undo.onPressed, isNull);
  });

  testWidgets('tapping the project name renames the project', (tester) async {
    await tester.runAsync(() => createProject(const []));
    await pumpEditor(tester);

    // The tap starts dialog → save; it must run in the real zone so the
    // save's Hive write can complete.
    await tester.runAsync(() async => tester.tap(find.byKey(const ValueKey('editor_title'))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('rename_field')), 'Diwali Offer');
    await tester.pump();
    await tapAndSettle(tester, find.byKey(const ValueKey('rename_save')));
    await pumpUntil(tester, () => canvas().project.title == 'Diwali Offer');

    expect(find.text('Diwali Offer'), findsOneWidget);
    final saved = await tester.runAsync(() => repository.loadProject(projectId));
    expect(saved!.title, 'Diwali Offer');
  });

  testWidgets('the empty canvas card adds a photo when tapped, or text from its button', (tester) async {
    await tester.runAsync(() => createProject(const []));
    await pumpEditor(tester);

    await tapAndSettle(tester, find.text('Start with a photo or some text'));
    expect(find.byKey(const ValueKey('photo_source_gallery')), findsOneWidget,
        reason: 'same as the Photo tool');
    Navigator.of(tester.element(find.byKey(const ValueKey('photo_source_gallery')))).pop();
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.byKey(const ValueKey('hint_add_text')));
    expect(find.text('Add Text'), findsOneWidget, reason: 'same as the Text tool');
  });

  group('app tour', () {
    final overlay = find.byKey(const ValueKey('tour_overlay'));
    const editorSteps = [
      'Add a photo',
      'Add text',
      'Stickers and your logo',
      'Background colour',
      'Undo, Redo and Layers',
      'Export',
    ];

    /// Text inside the tour bubble (the same words also appear on real buttons).
    Finder inTour(String text) => find.descendant(of: find.byKey(const ValueKey('tour_bubble')), matching: find.text(text));

    Future<void> next(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('tour_next')));
      await tester.pumpAndSettle();
    }

    testWidgets('the first visit tours the real tools, then never starts by itself again', (tester) async {
      await tester.runAsync(() => createProject(const [], toursUnseen: true));
      await pumpEditor(tester);

      expect(overlay, findsOneWidget);
      for (var i = 0; i < editorSteps.length; i++) {
        expect(inTour(editorSteps[i]), findsOneWidget, reason: 'step ${i + 1}');
        expect(find.text('${i + 1} of ${editorSteps.length}'), findsOneWidget);
        if (i < editorSteps.length - 1) await next(tester);
      }
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(overlay, findsNothing);
      expect(tutorial.seen, contains('editor'));
    });

    testWidgets('each step spotlights its real button, scrolling the tool row to it', (tester) async {
      await tester.runAsync(() => createProject(const [], toursUnseen: true));
      await pumpEditor(tester);

      for (final key in ['tool_photo', 'tool_text', 'tool_sticker', 'tool_background']) {
        final hole =
            (tester.widget<CustomPaint>(find.byKey(const ValueKey('tour_spotlight'))).painter! as SpotlightPainter).hole;
        final button = tester.getRect(find.byKey(ValueKey(key)));
        expect(hole.contains(button.center), isTrue, reason: key);
        expect(button.right, lessThanOrEqualTo(tester.view.physicalSize.width / tester.view.devicePixelRatio));
        await next(tester);
      }
    });

    testWidgets('Skip ends the tour', (tester) async {
      await tester.runAsync(() => createProject(const [], toursUnseen: true));
      await pumpEditor(tester);

      await tester.tap(find.byKey(const ValueKey('tour_skip')));
      await tester.pumpAndSettle();

      expect(overlay, findsNothing);
    });

    testWidgets('no automatic tour once seen, and the ? button replays it', (tester) async {
      await tester.runAsync(() => createProject(const []));
      await pumpEditor(tester);
      expect(overlay, findsNothing);

      await tester.tap(find.byKey(const ValueKey('editor_help')));
      await tester.pumpAndSettle();

      expect(overlay, findsOneWidget);
      expect(inTour('Add a photo'), findsOneWidget);
    });

    testWidgets('selecting a photo for the first time shows the Remove BG and Crop tips', (tester) async {
      await tester.runAsync(() => createProject(const [photo, caption], toursUnseen: true));
      await pumpEditor(tester);
      await tester.tap(find.byKey(const ValueKey('tour_skip')));
      await tester.pumpAndSettle();

      container.read(canvasProvider(projectId).notifier).selectLayer('photo');
      await tester.pumpAndSettle();

      expect(inTour('Remove the background'), findsOneWidget);
      await next(tester);
      expect(inTour('Crop'), findsOneWidget);
      await next(tester);
      expect(inTour('Lock'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      await next(tester);
      expect(overlay, findsNothing);
      expect(tutorial.seen, containsAll(['editor', 'photo_tools']));

      // Selecting a photo again, later, shows nothing.
      container.read(canvasProvider(projectId).notifier).selectLayer(null);
      await tester.pumpAndSettle();
      container.read(canvasProvider(projectId).notifier).selectLayer('photo');
      await tester.pumpAndSettle();
      expect(overlay, findsNothing);
    });

    testWidgets('selecting text for the first time shows the Edit tip', (tester) async {
      await tester.runAsync(() => createProject(const [photo, caption], toursUnseen: true));
      await pumpEditor(tester);
      await tester.tap(find.byKey(const ValueKey('tour_skip')));
      await tester.pumpAndSettle();

      container.read(canvasProvider(projectId).notifier).selectLayer('caption');
      await tester.pumpAndSettle();

      expect(inTour('Edit your text'), findsOneWidget);
      final hole =
          (tester.widget<CustomPaint>(find.byKey(const ValueKey('tour_spotlight'))).painter! as SpotlightPainter).hole;
      expect(hole.contains(tester.getCenter(find.byKey(const ValueKey('ctx_edit_text')))), isTrue);
    });

    testWidgets('layer tips wait for the main tour instead of stacking on it', (tester) async {
      await tester.runAsync(() => createProject(const [photo], toursUnseen: true));
      await pumpEditor(tester);
      expect(inTour('Add a photo'), findsOneWidget);

      container.read(canvasProvider(projectId).notifier).selectLayer('photo');
      await tester.pumpAndSettle();

      expect(inTour('Add a photo'), findsOneWidget, reason: 'still on the main tour');
      expect(inTour('Remove the background'), findsNothing);
      expect(tutorial.seen, isNot(contains('photo_tools')));
    });
  });

  testWidgets('Undo, Redo and Layers lead the tool row in every mode', (tester) async {
    await tester.runAsync(() => createProject(const [photo, caption]));
    await pumpEditor(tester);

    void expectQuickActionsInRow() {
      for (final key in ['editor_undo', 'editor_redo', 'editor_layers']) {
        expect(
          find.descendant(of: find.byKey(const ValueKey('editor_tool_row')), matching: find.byKey(ValueKey(key))),
          findsOneWidget,
          reason: key,
        );
      }
    }

    expectQuickActionsInRow();
    expect(find.byKey(const ValueKey('editor_export')), findsOneWidget, reason: 'Export stays in the top bar');
    expect(find.byKey(const ValueKey('empty_canvas_hint')), findsNothing, reason: 'the canvas has layers');

    container.read(canvasProvider(projectId).notifier).selectLayer('photo');
    await tester.pumpAndSettle();
    expectQuickActionsInRow();

    container.read(canvasProvider(projectId).notifier).selectLayer(null);
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.byKey(const ValueKey('tool_draw')));
    expect(find.byKey(const ValueKey('draw_bar')), findsOneWidget);
    expectQuickActionsInRow();
  });

  testWidgets('Lock in the layer tools and in the Layers sheet', (tester) async {
    await tester.runAsync(() => createProject(const [photo, caption]));
    await pumpEditor(tester);
    container.read(canvasProvider(projectId).notifier).selectLayer('caption');
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.byKey(const ValueKey('ctx_lock')));
    await pumpUntil(tester, () => canvas().project.layers.last.isLocked);
    expect(find.text('Unlock'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const ValueKey('editor_layers')));
    await tapAndSettle(tester, find.byKey(const ValueKey('layer_lock_caption')));
    await pumpUntil(tester, () => !canvas().project.layers.last.isLocked);
  });

  testWidgets('the Background tool sets the canvas color', (tester) async {
    await tester.runAsync(() => createProject(const []));
    await pumpEditor(tester);

    // The tool row scrolls: Background sits after Undo, Redo and Layers.
    await tester.ensureVisible(find.byKey(const ValueKey('tool_background')));
    await tester.pumpAndSettle();
    // The tap leads to a Hive write, so it starts in the real zone.
    await tester.runAsync(() async => tester.tap(find.byKey(const ValueKey('tool_background'))));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.byKey(const ValueKey('bg_preset_FACC15')));
    await pumpUntil(tester, () => canvas().project.backgroundColorValue == 0xFFFACC15);

    final saved = await tester.runAsync(() => repository.loadProject(projectId));
    expect(saved!.backgroundColorValue, 0xFFFACC15);
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
    expect(find.byKey(const ValueKey('ctx_crop')), findsOneWidget);
    expect(find.byKey(const ValueKey('ctx_reset_crop')), findsNothing, reason: 'not cropped');
    expect(find.byKey(const ValueKey('ctx_remove_bg')), findsOneWidget);
    expect(find.byKey(const ValueKey('ctx_edit_text')), findsNothing);

    await tapAndSettle(tester, find.byKey(const ValueKey('ctx_flip')));
    expect((canvas().project.layers.first as ImageLayer).isFlippedHorizontally, isTrue);

    await tapAndSettle(tester, find.byKey(const ValueKey('ctx_filters')));
    await tapAndSettle(tester, find.byKey(const ValueKey('filter_chip_grayscale')));
    expect((canvas().project.layers.first as ImageLayer).activeFilter, 'grayscale');

    // Undo is now available and reverts the filter.
    // History is written to disk before undo becomes available.
    await pumpUntil(
      tester,
      () => tester.widget<ToolButton>(find.byKey(const ValueKey('editor_undo'))).onPressed != null,
    );
    await tapAndSettle(tester, find.byKey(const ValueKey('editor_undo')));
    await pumpUntil(
      tester,
      () => (canvas().project.layers.first as ImageLayer).activeFilter == null,
    );
  });

  testWidgets('Remove BG offers the model download first, and "Not now" changes nothing',
      (tester) async {
    await tester.runAsync(() => createProject(const [photo, caption]));
    await pumpEditor(tester);
    installer.available = false;
    container.read(canvasProvider(projectId).notifier).selectLayer('photo');
    await tester.pumpAndSettle();
    final before = canvas().project.layers;

    await tapAndSettle(tester, find.byKey(const ValueKey('ctx_remove_bg')));
    expect(find.text('Download background remover?'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const ValueKey('bg_model_not_now')));
    expect(find.text('Download background remover?'), findsNothing);
    expect(installer.downloadStarts, 0);
    expect(canvas().project.layers, before);
    expect(find.byKey(const ValueKey('ctx_remove_bg')), findsOneWidget);
  });

  testWidgets('a cropped photo offers Uncrop, which restores the original', (tester) async {
    await tester.runAsync(
      () => createProject(const [
        ImageLayer(
          id: 'photo',
          x: 0.5,
          y: 0.5,
          relativeImagePath: 'projects/editor-screen/images/img.jpg',
          originalImagePath: 'projects/editor-screen/images/orig.jpg',
        ),
      ]),
    );
    await pumpEditor(tester);
    container.read(canvasProvider(projectId).notifier).selectLayer('photo');
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.byKey(const ValueKey('ctx_reset_crop')));

    final layer = canvas().project.layers.single as ImageLayer;
    expect(layer.relativeImagePath, 'projects/editor-screen/images/orig.jpg');
    expect(find.byKey(const ValueKey('ctx_reset_crop')), findsNothing);
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
