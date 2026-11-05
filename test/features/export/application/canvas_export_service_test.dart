import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
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

    test('content scales with the output size instead of shrinking', () async {
      // 20x20 green square centered at (25, 25) on a 100x100 canvas.
      final square = img.Image(width: 20, height: 20)
        ..clear(img.ColorRgba8(0, 255, 0, 255));
      final squareFile = File('${tempDir.path}/square.png');
      await squareFile.writeAsBytes(img.encodePng(square));
      when(() => mockRepo.resolveRelativePath('projects/p/images/square.png'))
          .thenAnswer((_) async => squareFile);

      final project = ProjectModel(
        id: 'proj_scale',
        title: 'Scale',
        canvasWidth: 100.0,
        canvasHeight: 100.0,
        layers: const [
          ImageLayer(
            id: 'sq',
            x: 0.25,
            y: 0.25,
            relativeImagePath: 'projects/p/images/square.png',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final service = CanvasExportService(projectRepository: mockRepo);

      bool isGreen(img.Image image, int x, int y) {
        final p = image.getPixel(x, y);
        return p.g > 200 && p.r < 60 && p.b < 60;
      }

      final x1 = img.decodePng(
        await service.renderAtSize(project: project, outputSize: const Size(100, 100)),
      )!;
      expect(isGreen(x1, 25, 25), isTrue);
      expect(isGreen(x1, 33, 33), isTrue);
      expect(isGreen(x1, 40, 40), isFalse);

      // Twice the resolution: the square spans canvas units 15..35 -> 30..70 px.
      final x2 = img.decodePng(
        await service.renderAtSize(project: project, outputSize: const Size(200, 200)),
      )!;
      expect(x2.width, 200);
      expect(isGreen(x2, 50, 50), isTrue);
      expect(isGreen(x2, 66, 66), isTrue, reason: 'content must grow with the output');
      expect(isGreen(x2, 75, 75), isFalse);
    });

    test('draws user stickers from their project file', () async {
      final sticker = img.Image(width: 10, height: 10)..clear(img.ColorRgba8(255, 0, 0, 255));
      final file = File('${tempDir.path}/sticker.png');
      await file.writeAsBytes(img.encodePng(sticker));
      when(() => mockRepo.resolveRelativePath('projects/p/images/sticker.png'))
          .thenAnswer((_) async => file);

      final project = ProjectModel(
        id: 'p',
        title: 'Stickers',
        canvasWidth: 40.0,
        canvasHeight: 40.0,
        layers: const [
          StickerLayer(
            id: 's',
            x: 0.5,
            y: 0.5,
            assetPath: 'stickers/s.png',
            relativeFilePath: 'projects/p/images/sticker.png',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final out = img.decodePng(
        await CanvasExportService(projectRepository: mockRepo)
            .renderAtSize(project: project, outputSize: const Size(40, 40)),
      )!;
      final center = out.getPixel(20, 20);
      expect(center.r, greaterThan(200));
      expect(center.g, lessThan(60));
    });

    test('renderCanvasToBytes uses the resolution tier and keeps the aspect ratio', () async {
      final service = CanvasExportService(projectRepository: mockRepo);
      final project = ProjectModel(
        id: 'proj_tier',
        title: 'Tier',
        canvasWidth: 40.0,
        canvasHeight: 50.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final standard = img.decodePng(
        await service.renderCanvasToBytes(project: project, config: const ExportConfig()),
      )!;
      expect(standard.width, 40);
      expect(standard.height, 50);
    });

    test('draws the logo watermark from its app-relative path', () async {
      final logo = img.Image(width: 50, height: 50)..clear(img.ColorRgba8(255, 0, 0, 255));
      final logoFile = File('${tempDir.path}/branding/logo.png');
      await logoFile.parent.create(recursive: true);
      await logoFile.writeAsBytes(img.encodePng(logo));

      final service = CanvasExportService(
        projectRepository: mockRepo,
        resolveAppFile: (relative) async => File('${tempDir.path}/$relative'),
      );
      final project = ProjectModel(
        id: 'logo',
        title: 'Logo',
        canvasWidth: 200.0,
        canvasHeight: 200.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final out = img.decodePng(
        await service.renderAtSize(
          project: project,
          outputSize: const Size(200, 200),
          watermark: const WatermarkConfig(
            isEnabled: true,
            type: WatermarkType.logo,
            logoRelativePath: 'branding/logo.png',
            opacity: 1.0,
          ),
        ),
      )!;

      // Logo is 20% of the width (40 px) with a 3% (6 px) margin, bottom right.
      final inLogo = out.getPixel(174, 174);
      expect(inLogo.r, greaterThan(200));
      expect(inLogo.g, lessThan(80));
      final outside = out.getPixel(100, 100);
      expect(outside.g, greaterThan(200), reason: 'rest of the canvas stays white');
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
}
