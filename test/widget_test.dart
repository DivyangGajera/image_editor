import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/onboarding/onboarding.dart';
import 'package:image_editor/features/projects/application/projects_notifier.dart';
import 'package:image_editor/features/projects/presentation/home_screen.dart';
import 'package:image_editor/main.dart';

void main() {
  testWidgets('app starts on the project gallery', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    late Directory tempDir;
    late ProjectRepository repository;
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('app_smoke_test_');
      await AppBootstrap.initialize(hivePath: tempDir.path);
      repository = ProjectRepository(
        getBaseDir: () async => tempDir,
        projectsBox: Hive.box<ProjectModel>(StorageKeys.projectsBox),
      );
    });
    addTearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [projectRepositoryProvider.overrideWithValue(repository)],
        child: const OfflineImageEditorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.appShortName), findsOneWidget);
    expect(find.text('What are you making today?'), findsOneWidget);
    expect(find.text('No designs yet'), findsOneWidget);
  });

  testWidgets('a first launch starts on the welcome, then Home', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final onboarding = _MemoryOnboarding();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(onboarding),
          projectsProvider.overrideWith(_NoProjects.new),
        ],
        child: const OfflineImageEditorApp(showWelcome: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('welcome_skip')));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(onboarding.seen, isTrue);
  });
}

class _MemoryOnboarding extends OnboardingRepository {
  bool seen = false;

  @override
  Future<bool> hasSeenWelcome() async => seen;

  @override
  Future<void> markWelcomeSeen() async => seen = true;
}

class _NoProjects extends ProjectsNotifier {
  @override
  Future<List<ProjectModel>> build() async => const [];
}
