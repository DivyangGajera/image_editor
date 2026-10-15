import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/export/application/canvas_export_service.dart';
import 'package:image_editor/features/export/domain/models/models.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProjectRepository mockRepo;
  late Directory tempDir;

  setUp(() async {
    mockRepo = MockProjectRepository();
    tempDir = await Directory.systemTemp.createTemp('canvas_export_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CanvasExportService.renderCanvasToBytes', () {
    test('renders blank project to valid PNG bytes', () async {
      final service = CanvasExportService(projectRepository: mockRepo);
      final project = ProjectModel(
        id: 'proj_1',
        title: 'Blank Project',
        canvasWidth: 200.0,
        canvasHeight: 150.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const config = ExportConfig(
        format: ExportFormat.png,
        width: 200.0,
        height: 150.0,
      );

      final bytes = await service.renderCanvasToBytes(
        project: project,
        config: config,
      );

      expect(bytes, isNotEmpty);
      // PNG magic number check: 0x89, 0x50, 0x4E, 0x47 (‰PNG)
      expect(bytes.sublist(0, 4), equals([0x89, 0x50, 0x4E, 0x47]));

      final decoded = img.decodePng(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(200));
      expect(decoded.height, equals(150));
    });

    test('renders project to valid JPEG bytes with custom quality', () async {
      final service = CanvasExportService(projectRepository: mockRepo);
      final project = ProjectModel(
        id: 'proj_2',
        title: 'JPEG Project',
        canvasWidth: 100.0,
        canvasHeight: 100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const config = ExportConfig(
        format: ExportFormat.jpeg,
        jpegQuality: 80,
        width: 100.0,
        height: 100.0,
      );

      final bytes = await service.renderCanvasToBytes(
        project: project,
        config: config,
      );

      expect(bytes, isNotEmpty);
      // JPEG magic number check: 0xFF, 0xD8
      expect(bytes[0], equals(0xFF));
      expect(bytes[1], equals(0xD8));

      final decoded = img.decodeJpg(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(100));
      expect(decoded.height, equals(100));
    });

    test('renders project containing TextLayer and DoodleLayer', () async {
      final service = CanvasExportService(projectRepository: mockRepo);

      const textLayer = TextLayer(
        id: 'txt_1',
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        zIndex: 0,
        isVisible: true,
        text: 'Offline Editor Stamp',
        fontSize: 16.0,
        textColorValue: 0xFF000000,
        boxColorValue: 0x33000000,
      );

      const doodleLayer = DoodleLayer(
        id: 'doodle_1',
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        zIndex: 1,
        isVisible: true,
        points: [
          [0.1, 0.1],
          [0.5, 0.5],
          [0.9, 0.9],
        ],
        strokeWidth: 4.0,
        strokeColorValue: 0xFFFF0000,
      );

      final project = ProjectModel(
        id: 'proj_composite',
        title: 'Composite Project',
        canvasWidth: 120.0,
        canvasHeight: 120.0,
        layers: [textLayer, doodleLayer],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const config = ExportConfig(
        format: ExportFormat.png,
        width: 120.0,
        height: 120.0,
      );

      final bytes = await service.renderCanvasToBytes(
        project: project,
        config: config,
      );

      expect(bytes, isNotEmpty);
      final decoded = img.decodePng(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(120));
      expect(decoded.height, equals(120));
    });

    test('renders project with ImageLayer loaded from repository', () async {
      // Create a small 20x20 PNG test image on disk
      final sampleImg = img.Image(width: 20, height: 20);
      img.fill(sampleImg, color: img.ColorRgba8(0, 255, 0, 255));
      final sampleBytes = Uint8List.fromList(img.encodePng(sampleImg));

      final testFile = File('${tempDir.path}/test_source.png');
      await testFile.writeAsBytes(sampleBytes);

      when(() => mockRepo.resolveRelativePath('assets/test_source.png'))
          .thenAnswer((_) async => testFile);

      const imageLayer = ImageLayer(
        id: 'img_1',
        x: 0.5,
        y: 0.5,
        scale: 1.0,
        rotation: 0.0,
        zIndex: 0,
        isVisible: true,
        relativeImagePath: 'assets/test_source.png',
        activeFilter: 'grayscale',
        isFlippedHorizontally: true,
      );

      final project = ProjectModel(
        id: 'proj_img',
        title: 'Image Layer Project',
        canvasWidth: 100.0,
        canvasHeight: 100.0,
        layers: [imageLayer],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final service = CanvasExportService(projectRepository: mockRepo);
      const config = ExportConfig(
        format: ExportFormat.png,
        width: 100.0,
        height: 100.0,
      );

      final bytes = await service.renderCanvasToBytes(
        project: project,
        config: config,
      );

      expect(bytes, isNotEmpty);
      final decoded = img.decodePng(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(100));
    });

    test('renders with watermarks across all positions', () async {
      final service = CanvasExportService(projectRepository: mockRepo);
      final project = ProjectModel(
        id: 'proj_wm',
        title: 'Watermark Test',
        canvasWidth: 200.0,
        canvasHeight: 200.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final positions = [
        WatermarkPosition.bottomRight,
        WatermarkPosition.bottomLeft,
        WatermarkPosition.center,
        WatermarkPosition.tiled,
      ];

      for (final pos in positions) {
        final config = ExportConfig(
          width: 200.0,
          height: 200.0,
          watermark: WatermarkConfig(
            isEnabled: true,
            text: 'STAMP $pos',
            position: pos,
            opacity: 0.5,
          ),
        );

        final bytes = await service.renderCanvasToBytes(
          project: project,
          config: config,
        );

        expect(bytes, isNotEmpty);
        final decoded = img.decodePng(bytes);
        expect(decoded, isNotNull);
      }
    });
  });

  group('CanvasExportService.saveExportToGallery', () {
    test('writes bytes into Exports directory and returns file path', () async {
      final service = CanvasExportService(
        projectRepository: mockRepo,
        picturesDirectoryProvider: () async => tempDir,
      );

      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final savedPath = await service.saveExportToGallery(
        bytes: bytes,
        filename: 'my_export.png',
      );

      expect(savedPath, contains('Exports'));
      expect(savedPath, endsWith('my_export.png'));

      final writtenFile = File(savedPath);
      expect(await writtenFile.exists(), isTrue);
      expect(await writtenFile.readAsBytes(), equals(bytes));
    });
  });
}
