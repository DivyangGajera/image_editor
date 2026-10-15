import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/core/utils/color_filters.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/presentation/widgets/layer_renderer.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  group('LayerRenderer GPU Filters and Flip', () {
    late MockProjectRepository mockRepo;
    late Directory tempDir;
    late File sampleImageFile;

    setUp(() async {
      mockRepo = MockProjectRepository();
      tempDir = await Directory.systemTemp.createTemp('layer_renderer_test_');
      sampleImageFile = File('${tempDir.path}/test_img.png');
      await sampleImageFile.writeAsBytes([1, 2, 3]);

      when(() => mockRepo.resolveRelativePath(any()))
          .thenAnswer((_) async => sampleImageFile);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    Widget createTestApp(CanvasLayer layer) {
      return ProviderScope(
        overrides: [
          projectRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: LayerRenderer(
              layer: layer,
              canvasSize: const Size(500, 500),
            ),
          ),
        ),
      );
    }

    testWidgets('renders ColorFiltered widget when activeFilter is set', (tester) async {
      const layerWithFilter = ImageLayer(
        id: 'img-filter',
        x: 0.5,
        y: 0.5,
        relativeImagePath: 'projects/p/images/img.png',
        activeFilter: 'grayscale',
      );

      await tester.pumpWidget(createTestApp(layerWithFilter));
      await tester.pumpAndSettle();

      final colorFilteredFinder = find.byType(ColorFiltered);
      expect(colorFilteredFinder, findsOneWidget);

      final colorFilteredWidget = tester.widget<ColorFiltered>(colorFilteredFinder);
      expect(
        colorFilteredWidget.colorFilter,
        equals(AppColorFilters.getFilterByName('grayscale')),
      );
    });

    testWidgets('renders Transform with horizontal flip when isFlippedHorizontally is true', (tester) async {
      const flippedLayer = ImageLayer(
        id: 'img-flip',
        x: 0.5,
        y: 0.5,
        relativeImagePath: 'projects/p/images/img.png',
        isFlippedHorizontally: true,
      );

      await tester.pumpWidget(createTestApp(flippedLayer));
      await tester.pumpAndSettle();

      final transformFinder = find.byKey(const ValueKey('horizontal_flip_transform'));
      expect(transformFinder, findsOneWidget);

      final transformWidget = tester.widget<Transform>(transformFinder);
      expect(transformWidget.alignment, equals(Alignment.center));
      expect(transformWidget.transform[0], equals(-1.0)); // Inverted X
      expect(transformWidget.transform[5], equals(1.0));  // Normal Y
    });

    testWidgets('does not add ColorFiltered or Transform when filter is null and not flipped', (tester) async {
      const normalLayer = ImageLayer(
        id: 'img-normal',
        x: 0.5,
        y: 0.5,
        relativeImagePath: 'projects/p/images/img.png',
        isFlippedHorizontally: false,
        activeFilter: null,
      );

      await tester.pumpWidget(createTestApp(normalLayer));
      await tester.pumpAndSettle();

      expect(find.byType(ColorFiltered), findsNothing);
      expect(find.byKey(const ValueKey('horizontal_flip_transform')), findsNothing);
    });
  });
}
