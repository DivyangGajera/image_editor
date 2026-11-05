import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/images/application/image_import_service.dart';
import 'package:image_editor/features/images/application/image_normalizer.dart';
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

    setUpAll(AppBootstrap.registerAdapters);

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

    test('returns null and deletes the saved original when the user cancels cropping',
        () async {
      final samplePicked = File('${tempDir.path}/picked_raw.png');
      await samplePicked.writeAsBytes(img.encodePng(img.Image(width: 40, height: 30)));

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
      final croppedFrom = verify(() => mockCropper.cropImage(
            sourcePath: captureAny(named: 'sourcePath'),
            uiSettings: any(named: 'uiSettings'),
          )).captured.single as String;
      expect(croppedFrom, contains('/projects/test-proj/images/orig_'));
      final imagesDir = Directory('${tempDir.path}/projects/test-proj/images');
      expect(
        imagesDir.existsSync() ? imagesDir.listSync() : const <FileSystemEntity>[],
        isEmpty,
        reason: 'a cancelled import must not leave files behind',
      );
    });

    Future<void> stubPickAndCrop(Uint8List croppedBytes) async {
      final samplePicked = File('${tempDir.path}/picked_raw.jpg');
      await samplePicked.writeAsBytes(img.encodeJpg(img.Image(width: 64, height: 48)));
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

    test('importPhoto reports the saved path and normalized pixel size', () async {
      final photo = img.Image(width: 3000, height: 1500)..clear(img.ColorRgb8(1, 2, 3));
      await stubPickAndCrop(Uint8List.fromList(img.encodeJpg(photo)));

      final imported = await service.importPhoto(
        source: ImageSource.gallery,
        projectId: 'test-proj',
      );

      expect(imported, isNotNull);
      expect(imported!.relativePath, startsWith('projects/test-proj/images/img_'));
      expect(imported.width, 2048);
      expect(imported.height, 1024);
      expect(imported.size, const Size(2048, 1024));
      expect(imported.originalPath, startsWith('projects/test-proj/images/orig_'));
      expect((await projectRepository.resolveRelativePath(imported.originalPath)).existsSync(), isTrue);
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

    test('pickAndCropImage records the original for later re-cropping', () async {
      await stubPickAndCrop(Uint8List.fromList(img.encodePng(img.Image(width: 20, height: 20))));

      final layer = await service.pickAndCropImage(
        source: ImageSource.gallery,
        projectId: 'test-proj',
        canvasSize: canvasSize,
      );

      expect(layer!.originalImagePath, startsWith('projects/test-proj/images/orig_'));
      expect(layer.isCropped, isTrue);
    });

    test('recrop crops from the given original and keeps pointing at it', () async {
      final originalPath = await projectRepository.saveLayerImage(
        'test-proj',
        Uint8List.fromList(img.encodePng(img.Image(width: 100, height: 100))),
        'orig_existing.png',
      );
      final cropped = File('${tempDir.path}/recropped');
      await cropped.writeAsBytes(img.encodePng(img.Image(width: 50, height: 40)));
      when(() => mockCropper.cropImage(
            sourcePath: any(named: 'sourcePath'),
            uiSettings: any(named: 'uiSettings'),
          )).thenAnswer((_) async => CroppedFile(cropped.path));

      final result = await service.recrop(projectId: 'test-proj', originalPath: originalPath);

      expect(result!.originalPath, originalPath);
      expect(result.width, 50);
      expect(result.height, 40);
      verify(() => mockCropper.cropImage(
            sourcePath: '${tempDir.path}/$originalPath',
            uiSettings: any(named: 'uiSettings'),
          )).called(1);
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
