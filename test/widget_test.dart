import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/main.dart';

void main() {
  testWidgets('app starts on the project gallery', (tester) async {
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
    expect(find.text('No projects yet'), findsOneWidget);
  });
}
