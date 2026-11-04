import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/images/application/image_import_service.dart';
import 'package:image_editor/features/images/application/image_normalizer.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockImagePicker extends Mock implements ImagePicker {}

class MockImageCropper extends Mock implements ImageCropper {}

void main() {
  group('ImageImportService', () {
    late Directory tempDir;
    late Box<ProjectModel> testBox;
    late ProjectRepository projectRepository;
    late MockImagePicker mockPicker;
    late MockImageCropper mockCropper;
    late ImageImportService service;
    const canvasSize = Size(1080, 1350);

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ImageLayerAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TextLayerAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DoodleLayerAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(StickerLayerAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ProjectModelAdapter());
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('image_import_test_');
      Hive.init(tempDir.path);
      testBox = await Hive.openBox<ProjectModel>(StorageKeys.projectsBox);

      projectRepository = ProjectRepository(
        getBaseDir: () async => tempDir,
        projectsBox: testBox,
      );

      mockPicker = MockImagePicker();
      mockCropper = MockImageCropper();

      service = ImageImportService(
        picker: mockPicker,
        cropper: mockCropper,
        // Synchronous normalization: tests must not spawn isolates.
        normalizer: (bytes) async => ImageNormalizer.normalize(bytes),
        projectRepository: projectRepository,
      );
    });

    tearDown(() async {
      if (testBox.isOpen) {
        await testBox.close();
      }
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns null when user cancels image picker', () async {
      when(() => mockPicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => null);

      final result = await service.pickAndCropImage(
        source: ImageSource.gallery,
        projectId: 'test-proj',
        canvasSize: canvasSize,
      );

      expect(result, isNull);
      verify(() => mockPicker.pickImage(source: ImageSource.gallery)).called(1);
      verifyZeroInteractions(mockCropper);
    });

    test('returns null when user cancels image cropper', () async {
      final samplePicked = File('${tempDir.path}/picked_raw.png');
      await samplePicked.writeAsBytes(Uint8List.fromList([1, 2, 3]));

      when(() => mockPicker.pickImage(source: ImageSource.camera))
          .thenAnswer((_) async => XFile(samplePicked.path));
      when(() => mockCropper.cropImage(
            sourcePath: any(named: 'sourcePath'),
            uiSettings: any(named: 'uiSettings'),
          )).thenAnswer((_) async => null);

      final result = await service.pickAndCropImage(
        source: ImageSource.camera,
        projectId: 'test-proj',
        canvasSize: canvasSize,
      );

      expect(result, isNull);
      verify(() => mockPicker.pickImage(source: ImageSource.camera)).called(1);
      verify(() => mockCropper.cropImage(
            sourcePath: samplePicked.path,
            uiSettings: any(named: 'uiSettings'),
          )).called(1);
    });

    Future<void> stubPickAndCrop(Uint8List croppedBytes) async {
      final samplePicked = File('${tempDir.path}/picked_raw.jpg');
      await samplePicked.writeAsBytes(<int>[10, 20, 30]);
      final sampleCropped = File('${tempDir.path}/cropped_output');
      await sampleCropped.writeAsBytes(croppedBytes);

      when(() => mockPicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => XFile(samplePicked.path));
      when(() => mockCropper.cropImage(
            sourcePath: any(named: 'sourcePath'),
            uiSettings: any(named: 'uiSettings'),
          )).thenAnswer((_) async => CroppedFile(sampleCropped.path));
    }

    test('saves a normalized opaque photo as JPEG and fits it to 70% of the canvas',
        () async {
      // 4000x2000 opaque photo -> downscaled to 2048x1024.
      final photo = img.Image(width: 4000, height: 2000)
        ..clear(img.ColorRgb8(200, 120, 40));
      await stubPickAndCrop(Uint8List.fromList(img.encodeJpg(photo)));

      final layer = await service.pickAndCropImage(
        source: ImageSource.gallery,
        projectId: 'test-proj',
        canvasSize: canvasSize,
      );

      expect(layer, isNotNull);
      expect(layer!.x, 0.5);
      expect(layer.y, 0.5);
      expect(layer.rotation, 0.0);
      expect(layer.relativeImagePath, startsWith('projects/test-proj/images/img_'));
      expect(layer.relativeImagePath, endsWith('.jpg'));
      // Width-limited: 1080 * 0.7 / 2048.
      expect(layer.scale, closeTo(1080 * 0.7 / 2048, 1e-9));

      final saved = await projectRepository.resolveRelativePath(layer.relativeImagePath);
      final decoded = img.decodeImage(await saved.readAsBytes())!;
      expect(decoded.width, ImageNormalizer.maxDimension);
      expect(decoded.height, 1024);
    });

    test('keeps transparency as PNG and never enlarges small images', () async {
      final sticker = img.Image(width: 200, height: 100, numChannels: 4)
        ..clear(img.ColorRgba8(0, 0, 0, 0));
      await stubPickAndCrop(Uint8List.fromList(img.encodePng(sticker)));

      final layer = await service.pickAndCropImage(
        source: ImageSource.gallery,
        projectId: 'test-proj',
        canvasSize: canvasSize,
      );

      expect(layer!.relativeImagePath, endsWith('.png'));
      expect(layer.scale, 1.0);
    });

    test('imageImportServiceProvider provides functional service', () {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepository),
        ],
      );
      addTearDown(container.dispose);

      final instance = container.read(imageImportServiceProvider);
      expect(instance, isA<ImageImportService>());
      expect(identical(instance.projectRepository, projectRepository), isTrue);
    });
  });
}
