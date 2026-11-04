import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/collage/application/collage_engine.dart';
import 'package:image_editor/features/collage/application/collage_notifier.dart';
import 'package:image_editor/features/collage/domain/models/models.dart';
import 'package:image_editor/features/collage/presentation/screens/collage_setup_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockImagePicker extends Mock implements ImagePicker {}

class MockCollageEngine extends Mock implements CollageEngine {}

class FakeCollageConfig extends Fake implements CollageConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCollageConfig());
  });

  group('CollageSetupScreen', () {
    late MockImagePicker mockPicker;
    late MockCollageEngine mockEngine;
    late Directory tempDir;
    late List<File> tempImageFiles;

    setUp(() async {
      mockPicker = MockImagePicker();
      mockEngine = MockCollageEngine();

      when(
        () => mockEngine.generateLayout(any(), any()),
      ).thenReturn([]);

      tempDir = await Directory.systemTemp.createTemp('collage_widget_test_');
      tempImageFiles = [];
      for (int i = 0; i < 3; i++) {
        final f = File('${tempDir.path}/test_img_$i.png');
        await f.writeAsBytes([0, 1, 2, 3]);
        tempImageFiles.add(f);
      }
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Widget buildTestableScreen({
      ValueChanged<ProjectModel>? onProjectCreated,
    }) {
      return ProviderScope(
        overrides: [
          collageEngineProvider.overrideWithValue(mockEngine),
        ],
        child: MaterialApp(
          home: CollageSetupScreen(
            imagePicker: mockPicker,
            onProjectCreated: onProjectCreated,
          ),
        ),
      );
    }

    testWidgets('renders all setup controls and initial disabled creation state', (tester) async {
      await tester.pumpWidget(buildTestableScreen());

      expect(find.text('Collage & Filmstrip'), findsOneWidget);
      expect(find.text('0 / 9 (Min 2)'), findsOneWidget);
      expect(find.byKey(const ValueKey('add_photos_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('collage_preview_box')), findsOneWidget);

      expect(find.byKey(const ValueKey('preset_grid')), findsOneWidget);
      expect(find.byKey(const ValueKey('preset_horizontal')), findsOneWidget);
      expect(find.byKey(const ValueKey('preset_vertical')), findsOneWidget);

      expect(find.byKey(const ValueKey('border_width_slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('spacing_slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('outer_margin_slider')), findsOneWidget);

      final topButton = tester.widget<TextButton>(
        find.byKey(const ValueKey('create_collage_project_button')),
      );
      expect(topButton.onPressed, isNull);

      final bottomButton = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('bottom_create_project_button')),
      );
      expect(bottomButton.onPressed, isNull);
    });

    testWidgets('picking images enables create button and displays thumbnail count', (tester) async {
      when(() => mockPicker.pickMultiImage(limit: 9)).thenAnswer(
        (_) async => [
          XFile(tempImageFiles[0].path),
          XFile(tempImageFiles[1].path),
        ],
      );

      await tester.pumpWidget(buildTestableScreen());

      // Tap add photos
      await tester.tap(find.byKey(const ValueKey('add_photos_button')));
      await tester.pumpAndSettle();

      expect(find.text('2 / 9 (Min 2)'), findsOneWidget);

      final topButton = tester.widget<TextButton>(
        find.byKey(const ValueKey('create_collage_project_button')),
      );
      expect(topButton.onPressed, isNotNull);

      // Verify remove button appears for each image
      expect(find.byKey(const ValueKey('remove_image_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('remove_image_1')), findsOneWidget);

      // Tap remove on first image
      await tester.tap(find.byKey(const ValueKey('remove_image_0')));
      await tester.pumpAndSettle();

      expect(find.text('1 / 9 (Min 2)'), findsOneWidget);
      final disabledTopButton = tester.widget<TextButton>(
        find.byKey(const ValueKey('create_collage_project_button')),
      );
      expect(disabledTopButton.onPressed, isNull);
    });

    testWidgets('tapping layout preset tiles switches layout type', (tester) async {
      await tester.pumpWidget(buildTestableScreen());

      // Ensure preset tile is visible in scrollview and tap
      await tester.ensureVisible(find.byKey(const ValueKey('preset_horizontal')));
      await tester.tap(find.byKey(const ValueKey('preset_horizontal')));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(CollageSetupScreen));
      final container = ProviderScope.containerOf(element);
      expect(
        container.read(collageProvider).config.layoutType,
        equals(CollageLayoutType.horizontalStrip),
      );

      // Tap vertical preset
      await tester.ensureVisible(find.byKey(const ValueKey('preset_vertical')));
      await tester.tap(find.byKey(const ValueKey('preset_vertical')));
      await tester.pumpAndSettle();

      expect(
        container.read(collageProvider).config.layoutType,
        equals(CollageLayoutType.verticalStrip),
      );
    });

    testWidgets('selecting border color updates config', (tester) async {
      await tester.pumpWidget(buildTestableScreen());

      // Tap gold color (0xFFFFD700 -> 'ffffd700')
      const goldKey = ValueKey('collage_color_ffffd700');
      await tester.ensureVisible(find.byKey(goldKey));
      await tester.tap(find.byKey(goldKey));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(CollageSetupScreen));
      final container = ProviderScope.containerOf(element);
      expect(
        container.read(collageProvider).config.borderColorValue,
        equals(0xFFFFD700),
      );
    });

    testWidgets('tapping create project executes creation and invokes callback', (tester) async {
      final fakeProject = ProjectModel(
        id: 'p_collage',
        title: 'Collage Project',
        canvasWidth: 1080,
        canvasHeight: 1080,
        createdAt: DateTime(2026, 10, 15),
        updatedAt: DateTime(2026, 10, 15),
        layers: [],
      );

      when(() => mockPicker.pickMultiImage(limit: 9)).thenAnswer(
        (_) async => [
          XFile(tempImageFiles[0].path),
          XFile(tempImageFiles[1].path),
        ],
      );

      when(
        () => mockEngine.createCollageProject(
          imagePaths: any(named: 'imagePaths'),
          config: any(named: 'config'),
          projectTitle: any(named: 'projectTitle'),
        ),
      ).thenAnswer((_) async => fakeProject);

      ProjectModel? createdProject;
      await tester.pumpWidget(
        buildTestableScreen(
          onProjectCreated: (p) => createdProject = p,
        ),
      );

      // Add photos
      await tester.tap(find.byKey(const ValueKey('add_photos_button')));
      await tester.pumpAndSettle();

      // Tap bottom create project button
      await tester.ensureVisible(find.byKey(const ValueKey('bottom_create_project_button')));
      await tester.tap(find.byKey(const ValueKey('bottom_create_project_button')));
      await tester.pumpAndSettle();

      expect(createdProject, equals(fakeProject));
    });
  });
}
