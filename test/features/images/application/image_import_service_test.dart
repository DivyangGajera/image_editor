import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/images/application/image_import_service.dart';
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
      );

      expect(result, isNull);
      verify(() => mockPicker.pickImage(source: ImageSource.camera)).called(1);
      verify(() => mockCropper.cropImage(
            sourcePath: samplePicked.path,
            uiSettings: any(named: 'uiSettings'),
          )).called(1);
    });

    test('successfully picks, crops, saves to sandbox, and returns ImageLayer', () async {
      final samplePicked = File('${tempDir.path}/picked_raw.png');
      await samplePicked.writeAsBytes(Uint8List.fromList([10, 20, 30]));

      final sampleCropped = File('${tempDir.path}/cropped_output.png');
      await sampleCropped.writeAsBytes(Uint8List.fromList([100, 200, 255]));

      when(() => mockPicker.pickImage(source: ImageSource.gallery))
          .thenAnswer((_) async => XFile(samplePicked.path));
      when(() => mockCropper.cropImage(
            sourcePath: any(named: 'sourcePath'),
            uiSettings: any(named: 'uiSettings'),
          )).thenAnswer((_) async => CroppedFile(sampleCropped.path));

      final layer = await service.pickAndCropImage(
        source: ImageSource.gallery,
        projectId: 'test-proj',
      );

      expect(layer, isNotNull);
      expect(layer!.id, isNotEmpty);
      expect(layer.x, equals(0.5));
      expect(layer.y, equals(0.5));
      expect(layer.scale, equals(1.0));
      expect(layer.rotation, equals(0.0));
      expect(layer.isVisible, isTrue);
      expect(layer.isFlippedHorizontally, isFalse);
      expect(layer.activeFilter, isNull);
      expect(layer.relativeImagePath, startsWith('projects/test-proj/images/img_'));
      expect(layer.relativeImagePath, endsWith('.png'));

      // Verify the file was persisted to disk in sandbox
      final savedFile = await projectRepository.resolveRelativePath(layer.relativeImagePath);
      expect(savedFile.existsSync(), isTrue);
      expect(await savedFile.readAsBytes(), equals([100, 200, 255]));
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
