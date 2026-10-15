import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/collage/application/collage_engine.dart';
import 'package:image_editor/features/collage/domain/models/models.dart';
import 'package:image_editor/features/layers/domain/models/image_layer.dart';
import 'package:mocktail/mocktail.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

class FakeProjectModel extends Fake implements ProjectModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProjectModel());
    registerFallbackValue(Uint8List(0));
  });

  group('CollageEngine Layout Algorithms', () {
    late MockProjectRepository mockRepo;
    late CollageEngine engine;

    setUp(() {
      mockRepo = MockProjectRepository();
      engine = CollageEngine(projectRepository: mockRepo);
    });

    test('horizontalStrip computes even horizontal distribution and normalized coordinates', () {
      final paths = ['img1.png', 'img2.png', 'img3.png'];
      final cells = engine.horizontalStrip(
        paths,
        10.0,
        outerMargin: 20.0,
        canvasWidth: 1000.0,
        canvasHeight: 500.0,
      );

      expect(cells.length, equals(3));

      // Available width: 1000 - 40 - (2 * 10) = 940 -> cellWidth = 940 / 3
      const expectedWidth = 940.0 / 3.0;
      const expectedHeight = 500.0 - 40.0; // 460

      for (int i = 0; i < 3; i++) {
        expect(cells[i].width, closeTo(expectedWidth, 0.001));
        expect(cells[i].height, closeTo(expectedHeight, 0.001));
        expect(cells[i].y, closeTo(0.5, 0.001)); // Centered vertically
        expect(cells[i].zIndex, equals(i));
        expect(cells[i].sourceImagePath, equals(paths[i]));
      }

      // X centers must be strictly increasing
      expect(cells[0].x, lessThan(cells[1].x));
      expect(cells[1].x, lessThan(cells[2].x));
    });

    test('horizontalStrip returns empty list for empty paths', () {
      final cells = engine.horizontalStrip([], 10.0);
      expect(cells, isEmpty);
    });

    test('verticalStrip computes stacked vertical distribution and normalized coordinates', () {
      final paths = ['img1.png', 'img2.png', 'img3.png'];
      final cells = engine.verticalStrip(
        paths,
        10.0,
        outerMargin: 20.0,
        canvasWidth: 500.0,
        canvasHeight: 1000.0,
      );

      expect(cells.length, equals(3));

      // Available height: 1000 - 40 - (2 * 10) = 940 -> cellHeight = 940 / 3
      const expectedHeight = 940.0 / 3.0;
      const expectedWidth = 500.0 - 40.0; // 460

      for (int i = 0; i < 3; i++) {
        expect(cells[i].width, closeTo(expectedWidth, 0.001));
        expect(cells[i].height, closeTo(expectedHeight, 0.001));
        expect(cells[i].x, closeTo(0.5, 0.001)); // Centered horizontally
        expect(cells[i].zIndex, equals(i));
      }

      // Y centers must be strictly increasing
      expect(cells[0].y, lessThan(cells[1].y));
      expect(cells[1].y, lessThan(cells[2].y));
    });

    test('verticalStrip returns empty list for empty paths', () {
      final cells = engine.verticalStrip([], 10.0);
      expect(cells, isEmpty);
    });

    test('gridMatrix calculates rows and columns within canvas bounds', () {
      final paths = ['a.png', 'b.png', 'c.png', 'd.png'];
      final cells = engine.gridMatrix(
        paths,
        2,
        2,
        10.0,
        outerMargin: 20.0,
        canvasWidth: 1000.0,
        canvasHeight: 1000.0,
      );

      expect(cells.length, equals(4));

      // Available: 1000 - 40 - 10 = 950 -> cell: 475x475
      const expectedSize = 475.0;

      for (final cell in cells) {
        expect(cell.width, closeTo(expectedSize, 0.001));
        expect(cell.height, closeTo(expectedSize, 0.001));
      }

      // First row y should be equal for (0,0) and (0,1)
      expect(cells[0].y, equals(cells[1].y));
      // Second row y should be equal for (1,0) and (1,1)
      expect(cells[2].y, equals(cells[3].y));
      // First row y should be less than second row y
      expect(cells[0].y, lessThan(cells[2].y));

      // First column x should be less than second column x
      expect(cells[0].x, lessThan(cells[1].x));
      expect(cells[2].x, lessThan(cells[3].x));
    });

    test('generateLayout routes based on configuration layoutType', () {
      final paths = ['a.png', 'b.png', 'c.png'];

      final hCells = engine.generateLayout(
        paths,
        const CollageConfig(layoutType: CollageLayoutType.horizontalStrip),
      );
      expect(hCells.length, equals(3));
      expect(hCells.first.y, equals(0.5));

      final vCells = engine.generateLayout(
        paths,
        const CollageConfig(layoutType: CollageLayoutType.verticalStrip),
      );
      expect(vCells.length, equals(3));
      expect(vCells.first.x, equals(0.5));

      final gCells = engine.generateLayout(
        paths,
        const CollageConfig(layoutType: CollageLayoutType.gridMatrix),
      );
      expect(gCells.length, equals(3));
    });
  });

  group('CollageEngine Isolate Processing & Project Creation', () {
    late MockProjectRepository mockRepo;
    late CollageEngine engine;
    late Directory tempDir;
    late List<File> tempFiles;

    setUp(() async {
      mockRepo = MockProjectRepository();
      when(() => mockRepo.saveLayerImage(any(), any(), any()))
          .thenAnswer((inv) async => 'projects/p1/images/${inv.positionalArguments[2]}');
      when(() => mockRepo.saveProject(any())).thenAnswer((_) async {});
      engine = CollageEngine(projectRepository: mockRepo);

      tempDir = await Directory.systemTemp.createTemp('collage_test_');
      tempFiles = [];

      for (int i = 0; i < 3; i++) {
        final file = File('${tempDir.path}/img_$i.png');
        final imgObj = img.Image(width: 40, height: 40);
        imgObj.clear(img.ColorRgba8(i * 50, 100, 150, 255));
        await file.writeAsBytes(img.encodePng(imgObj));
        tempFiles.add(file);
      }
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('executeCellProcessing resizes, applies border frame and encodes PNG', () {
      final srcImage = img.Image(width: 60, height: 40);
      srcImage.clear(img.ColorRgba8(255, 0, 0, 255));
      final srcBytes = Uint8List.fromList(img.encodePng(srcImage));

      final processedBytes = CollageEngine.executeCellProcessing(
        FramedCellParams(
          sourceBytes: srcBytes,
          targetWidth: 50,
          targetHeight: 50,
          borderWidth: 4,
          borderColorValue: 0xFFFFFFFF,
        ),
      );

      final decoded = img.decodePng(processedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(50));
      expect(decoded.height, equals(50));
      // Corner pixel (0, 0) should be border color (white)
      expect(decoded.getPixel(0, 0).r, equals(255));
      expect(decoded.getPixel(0, 0).g, equals(255));
      expect(decoded.getPixel(0, 0).b, equals(255));
    });

    test('createCollageProject builds ImageLayers and saves in sandbox repository', () async {
      when(() => mockRepo.saveLayerImage(any(), any(), any()))
          .thenAnswer((inv) async => 'projects/p1/images/${inv.positionalArguments[2]}');
      when(() => mockRepo.saveProject(any())).thenAnswer((_) async {});

      final imagePaths = tempFiles.map((f) => f.path).toList();
      final project = await engine.createCollageProject(
        imagePaths: imagePaths,
        config: const CollageConfig(
          layoutType: CollageLayoutType.horizontalStrip,
          borderWidth: 2,
        ),
        projectTitle: 'Trip Memories',
      );

      expect(project.title, equals('Trip Memories'));
      expect(project.layers.length, equals(3));
      for (final layer in project.layers.cast<ImageLayer>()) {
        expect(layer.isVisible, isTrue);
        expect(layer.scale, equals(1.0));
        expect(layer.relativeImagePath, startsWith('projects/p1/images/cell_'));
      }

      verify(() => mockRepo.saveLayerImage(project.id, any(), any())).called(3);
      verify(() => mockRepo.saveProject(project)).called(1);
    });

    test('createCollageProject throws ArgumentError when image count is < 2 or > 9', () async {
      final singlePath = [tempFiles.first.path];

      await expectLater(
        engine.createCollageProject(
          imagePaths: singlePath,
          config: const CollageConfig(),
        ),
        throwsArgumentError,
      );
    });

    test('createCollageProject throws ArgumentError if an image file does not exist', () async {
      final invalidPaths = [tempFiles.first.path, '${tempDir.path}/missing.png'];

      await expectLater(
        engine.createCollageProject(
          imagePaths: invalidPaths,
          config: const CollageConfig(),
        ),
        throwsArgumentError,
      );
    });
  });
}
