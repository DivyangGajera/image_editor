import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/collage/application/collage_engine.dart';
import 'package:image_editor/features/collage/application/collage_notifier.dart';
import 'package:image_editor/features/collage/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockCollageEngine extends Mock implements CollageEngine {}

class FakeCollageConfig extends Fake implements CollageConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCollageConfig());
  });

  group('CollageState', () {
    test('canCreate is true only when image count is between 2 and 9 and not creating', () {
      const state0 = CollageState(selectedImagePaths: []);
      expect(state0.canCreate, isFalse);

      const state1 = CollageState(selectedImagePaths: ['1.png']);
      expect(state1.canCreate, isFalse);

      const state2 = CollageState(selectedImagePaths: ['1.png', '2.png']);
      expect(state2.canCreate, isTrue);

      final state9 = CollageState(
        selectedImagePaths: List.generate(9, (i) => '$i.png'),
      );
      expect(state9.canCreate, isTrue);

      final state10 = CollageState(
        selectedImagePaths: List.generate(10, (i) => '$i.png'),
      );
      expect(state10.canCreate, isFalse);

      final stateCreating = state2.copyWith(isCreating: true);
      expect(stateCreating.canCreate, isFalse);
    });
  });

  group('CollageNotifier', () {
    late MockCollageEngine mockEngine;
    late ProviderContainer container;

    setUp(() {
      mockEngine = MockCollageEngine();
      container = ProviderContainer(
        overrides: [
          collageEngineProvider.overrideWithValue(mockEngine),
        ],
      );
      // Collage state is session-scoped (auto-disposed); keep it alive per test.
      container.listen(collageProvider, (_, _) {});
    });

    tearDown(() {
      container.dispose();
    });

    test('addImages adds unique paths up to 9 maximum', () {
      final notifier = container.read(collageProvider.notifier);

      notifier.addImages(['img1.png', 'img2.png']);
      expect(container.read(collageProvider).selectedImagePaths,
          equals(['img1.png', 'img2.png']));
      expect(container.read(collageProvider).canCreate, isTrue);

      // Duplicate should not be re-added
      notifier.addImages(['img2.png', 'img3.png']);
      expect(container.read(collageProvider).selectedImagePaths,
          equals(['img1.png', 'img2.png', 'img3.png']));

      // Adding 10 items should clamp to 9 total
      notifier.addImages(List.generate(10, (i) => 'extra_$i.png'));
      expect(container.read(collageProvider).selectedImagePaths.length,
          equals(9));
    });

    test('removeImage removes image at specified index', () {
      final notifier = container.read(collageProvider.notifier);
      notifier.addImages(['a.png', 'b.png', 'c.png']);

      notifier.removeImage(1); // Remove 'b.png'
      expect(container.read(collageProvider).selectedImagePaths,
          equals(['a.png', 'c.png']));

      notifier.removeImage(1); // Remove 'c.png'
      expect(container.read(collageProvider).selectedImagePaths,
          equals(['a.png']));
      expect(container.read(collageProvider).canCreate, isFalse);
    });

    test('reorderImages reorders elements correctly', () {
      final notifier = container.read(collageProvider.notifier);
      notifier.addImages(['first.png', 'second.png', 'third.png']);

      notifier.reorderImages(0, 3); // Move first to last
      expect(container.read(collageProvider).selectedImagePaths,
          equals(['second.png', 'third.png', 'first.png']));
    });

    test('updates config parameters (preset, border width, color, margin, spacing)', () {
      final notifier = container.read(collageProvider.notifier);

      notifier.setLayoutType(CollageLayoutType.verticalStrip);
      expect(container.read(collageProvider).config.layoutType,
          equals(CollageLayoutType.verticalStrip));

      notifier.setBorderWidth(15.0);
      expect(container.read(collageProvider).config.borderWidth,
          equals(15.0));

      notifier.setBorderColor(0xFFFFD700);
      expect(container.read(collageProvider).config.borderColorValue,
          equals(0xFFFFD700));

      notifier.setSpacing(20.0);
      expect(container.read(collageProvider).config.spacing,
          equals(20.0));

      notifier.setOuterMargin(30.0);
      expect(container.read(collageProvider).config.outerMargin,
          equals(30.0));
    });

    test('createProject returns null when canCreate is false', () async {
      final notifier = container.read(collageProvider.notifier);
      final result = await notifier.createProject();
      expect(result, isNull);
    });

    test('createProject coordinates with CollageEngine and returns ProjectModel', () async {
      final testProject = ProjectModel(
        id: 'proj_col',
        title: 'Collage Test',
        canvasWidth: 1080,
        canvasHeight: 1080,
        createdAt: DateTime(2026, 10, 15),
        updatedAt: DateTime(2026, 10, 15),
        layers: [],
      );

      when(
        () => mockEngine.createCollageProject(
          imagePaths: any(named: 'imagePaths'),
          config: any(named: 'config'),
          projectTitle: any(named: 'projectTitle'),
        ),
      ).thenAnswer((_) async => testProject);

      final notifier = container.read(collageProvider.notifier);
      notifier.addImages(['img1.png', 'img2.png']);

      final project = await notifier.createProject(title: 'My Collage');
      expect(project, equals(testProject));
      expect(container.read(collageProvider).isCreating, isFalse);
      expect(container.read(collageProvider).error, isNull);
    });

    test('createProject sets error state when engine throws', () async {
      when(
        () => mockEngine.createCollageProject(
          imagePaths: any(named: 'imagePaths'),
          config: any(named: 'config'),
          projectTitle: any(named: 'projectTitle'),
        ),
      ).thenThrow(Exception('Failed to process cell'));

      final notifier = container.read(collageProvider.notifier);
      notifier.addImages(['img1.png', 'img2.png']);

      await expectLater(
        notifier.createProject(),
        throwsA(isA<Exception>()),
      );

      expect(container.read(collageProvider).isCreating, isFalse);
      expect(container.read(collageProvider).error,
          contains('Failed to process cell'));
    });

    test('reset restores state to default', () {
      final notifier = container.read(collageProvider.notifier);
      notifier.addImages(['img1.png', 'img2.png']);
      notifier.setBorderWidth(25.0);

      notifier.reset();
      expect(container.read(collageProvider).selectedImagePaths, isEmpty);
      expect(container.read(collageProvider).config.borderWidth, equals(4.0));
    });
  });
}
