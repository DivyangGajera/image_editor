import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/projects/projects.dart';

import '../../../helpers/pump_until.dart';

void main() {
  late Directory tempDir;
  late ProjectRepository repository;
  late ProviderContainer container;
  late List<String> openedProjects;

  setUpAll(AppBootstrap.registerAdapters);

  Future<void> setUpStorage(List<ProjectModel> existing) async {
    tempDir = await Directory.systemTemp.createTemp('home_screen_test_');
    Hive.init(tempDir.path);
    repository = ProjectRepository(
      getBaseDir: () async => tempDir,
      projectsBox: await Hive.openBox<ProjectModel>(StorageKeys.projectsBox),
    );
    for (final project in existing) {
      await repository.saveProject(project);
    }
    container = ProviderContainer(
      overrides: [projectRepositoryProvider.overrideWithValue(repository)],
    );
    // Load the list outside the fake-async zone.
    await container.read(projectsProvider.future);
  }

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  ProjectModel project(String id, String title, {int minutesAgo = 0}) {
    final at = DateTime.now().subtract(Duration(minutes: minutesAgo));
    return ProjectModel(id: id, title: title, createdAt: at, updatedAt: at);
  }

  Future<void> pumpHome(WidgetTester tester) async {
    openedProjects = <String>[];
    // A typical phone screen (393 x 851 logical px).
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: HomeScreen(
            openEditor: (context, projectId) async => openedProjects.add(projectId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Taps [finder]; anything it triggers that touches Hive or renders a
  /// thumbnail runs outside the fake-async zone.
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }

  Future<List<ProjectModel>> savedProjects() => repository.getAllProjects();


  testWidgets('fresh install shows every way to create and an empty designs hint', (tester) async {
    await tester.runAsync(() => setUpStorage(const []));
    await pumpHome(tester);

    expect(find.text('What are you making today?'), findsOneWidget);
    for (final key in [
      'format_square',
      'format_portrait',
      'format_story',
      'format_landscape',
      'start_from_gallery',
      'start_from_camera',
      'start_collage',
      'start_custom_size',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    expect(find.text('No designs yet'), findsOneWidget);
  });

  testWidgets('one tap on Feed creates a 4:5 project and opens it in the editor', (tester) async {
    await tester.runAsync(() => setUpStorage(const []));
    await pumpHome(tester);

    await tapAndSettle(tester, find.byKey(const ValueKey('format_portrait')));
    await pumpUntil(tester, () => openedProjects.isNotEmpty);

    final saved = await tester.runAsync(savedProjects);
    expect(saved, hasLength(1));
    expect(saved!.single.canvasWidth, 1080);
    expect(saved.single.canvasHeight, 1350);
    expect(openedProjects, [saved.single.id]);
  });

  testWidgets('lists projects newest first and opens one on tap', (tester) async {
    await tester.runAsync(
      () => setUpStorage([
        // Minutes, not hours: an hours-old edit reads "yesterday" right after midnight.
        project('old', 'Old flyer', minutesAgo: 30),
        project('new', 'New banner', minutesAgo: 1),
      ]),
    );
    await pumpHome(tester);

    final cards = tester
        .widgetList<ProjectCard>(find.byType(ProjectCard))
        .map((card) => card.project.id)
        .toList();
    expect(cards, ['new', 'old']);
    expect(find.text('Edited 30 min ago'), findsOneWidget);

    await tapAndSettle(tester, find.text('Old flyer'));
    expect(openedProjects, ['old']);
    // Returning from the editor refreshes the thumbnail in the background;
    // let it finish before storage is torn down.
    await pumpUntil(
      tester,
      () => File('${tempDir.path}/projects/old/thumbnail.png').existsSync(),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  });

  testWidgets('rename and delete from the project options', (tester) async {
    await tester.runAsync(() => setUpStorage([project('p1', 'Draft')]));
    await pumpHome(tester);

    await tapAndSettle(tester, find.byKey(const ValueKey('project_menu_p1')));
    await tapAndSettle(tester, find.byKey(const ValueKey('project_action_rename')));
    await tester.enterText(find.byKey(const ValueKey('rename_field')), 'Diwali Offer');
    await tester.pump();
    await tapAndSettle(tester, find.byKey(const ValueKey('rename_save')));
    await pumpUntil(tester, () => find.text('Diwali Offer').evaluate().isNotEmpty);
    expect(find.text('Diwali Offer'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const ValueKey('project_menu_p1')));
    await tapAndSettle(tester, find.byKey(const ValueKey('project_action_delete')));
    expect(find.text('Delete project?'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const ValueKey('confirm_delete')));
    await pumpUntil(tester, () => find.text('No designs yet').evaluate().isNotEmpty);

    expect(await tester.runAsync(savedProjects), isEmpty);
    expect(find.text('No designs yet'), findsOneWidget);
  });

  testWidgets('custom size only accepts sides within the allowed range', (tester) async {
    await tester.runAsync(() => setUpStorage(const []));
    await pumpHome(tester);

    await tapAndSettle(tester, find.byKey(const ValueKey('start_custom_size')));

    await tester.enterText(find.byKey(const ValueKey('custom_width')), '50');
    await tester.pump();
    final create = find.byKey(const ValueKey('custom_size_create'));
    expect(tester.widget<FilledButton>(create).onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('custom_width')), '1600');
    await tester.enterText(find.byKey(const ValueKey('custom_height')), '900');
    await tester.pump();
    await tapAndSettle(tester, create);
    await pumpUntil(tester, () => openedProjects.isNotEmpty);

    final saved = await tester.runAsync(savedProjects);
    expect(saved!.single.canvasWidth, 1600);
    expect(saved.single.canvasHeight, 900);
  });
}
