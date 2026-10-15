import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/segmentation/application/background_removal_service.dart';
import 'package:image_editor/features/segmentation/application/pixel_cutout_processor.dart';
import 'package:mocktail/mocktail.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

class MockSelfieSegmenter extends Mock implements SelfieSegmenter {}

class MockPixelCutoutProcessor extends Mock implements PixelCutoutProcessor {}

class FakeInputImage extends Fake implements InputImage {}

class FakeCutoutProcessingParams extends Fake implements CutoutProcessingParams {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeInputImage());
    registerFallbackValue(FakeCutoutProcessingParams());
    registerFallbackValue(Uint8List(0));
  });

  group('BackgroundRemovalService', () {
    late MockProjectRepository mockProjectRepo;
    late MockSelfieSegmenter mockSegmenter;
    late MockPixelCutoutProcessor mockProcessor;
    late Directory tempDir;
    late File tempImageFile;

    setUp(() async {
      mockProjectRepo = MockProjectRepository();
      mockSegmenter = MockSelfieSegmenter();
      mockProcessor = MockPixelCutoutProcessor();

      tempDir = await Directory.systemTemp.createTemp('bg_removal_test_');
      tempImageFile = File('${tempDir.path}/test_source.png');

      final sampleImage = img.Image(width: 2, height: 2);
      await tempImageFile.writeAsBytes(img.encodePng(sampleImage));
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('extracts background, delegates to isolate, saves cutout, and returns ImageLayer', () async {
      final mask = SegmentationMask(
        width: 2,
        height: 2,
        confidences: [0.1, 0.9, 0.2, 0.85],
      );

      when(() => mockSegmenter.processImage(any())).thenAnswer((_) async => mask);
      when(() => mockSegmenter.close()).thenAnswer((_) async {});

      final fakeCutoutBytes = Uint8List.fromList([10, 20, 30, 40]);
      when(() => mockProcessor.processCutout(any())).thenAnswer((_) async => fakeCutoutBytes);

      when(() => mockProjectRepo.saveLayerImage(any(), any(), any()))
          .thenAnswer((_) async => 'projects/proj_1/images/cutout_sample.png');

      final service = BackgroundRemovalService(
        projectRepository: mockProjectRepo,
        pixelCutoutProcessor: mockProcessor,
        segmenterFactory: () => mockSegmenter,
      );

      final layer = await service.removeBackground(
        sourceImagePath: tempImageFile.path,
        projectId: 'proj_1',
      );

      expect(layer.relativeImagePath, equals('projects/proj_1/images/cutout_sample.png'));
      expect(layer.x, equals(0.5));
      expect(layer.y, equals(0.5));
      expect(layer.scale, equals(1.0));
      expect(layer.isVisible, isTrue);

      verify(() => mockSegmenter.processImage(any())).called(1);
      verify(() => mockSegmenter.close()).called(1);
      verify(() => mockProcessor.processCutout(any())).called(1);
      verify(() => mockProjectRepo.saveLayerImage('proj_1', fakeCutoutBytes, any())).called(1);
    });

    test('throws ArgumentError when source image does not exist', () async {
      final service = BackgroundRemovalService(
        projectRepository: mockProjectRepo,
        pixelCutoutProcessor: mockProcessor,
        segmenterFactory: () => mockSegmenter,
      );

      await expectLater(
        service.removeBackground(
          sourceImagePath: '${tempDir.path}/non_existent.png',
          projectId: 'proj_1',
        ),
        throwsArgumentError,
      );
    });

    test('throws StateError when SelfieSegmenter produces null mask', () async {
      when(() => mockSegmenter.processImage(any())).thenAnswer((_) async => null);
      when(() => mockSegmenter.close()).thenAnswer((_) async {});

      final service = BackgroundRemovalService(
        projectRepository: mockProjectRepo,
        pixelCutoutProcessor: mockProcessor,
        segmenterFactory: () => mockSegmenter,
      );

      await expectLater(
        service.removeBackground(
          sourceImagePath: tempImageFile.path,
          projectId: 'proj_1',
        ),
        throwsStateError,
      );

      verify(() => mockSegmenter.close()).called(1);
    });
  });
}
