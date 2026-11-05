import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/segmentation/application/background_removal_service.dart';
import 'package:image_editor/features/segmentation/application/pixel_cutout_processor.dart';
import 'package:image_editor/features/segmentation/application/subject_model_installer.dart';
import 'package:mocktail/mocktail.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

/// Marks the left half of the image as the subject.
class LeftHalfMasker implements SubjectMasker {
  final List<String> paths = [];
  final List<int> analysedWidths = [];

  @override
  Future<List<double>> maskFor(String imagePath) async {
    paths.add(imagePath);
    final image = img.decodeImage(await File(imagePath).readAsBytes())!;
    analysedWidths.add(image.width);
    return [
      for (var y = 0; y < image.height; y++)
        for (var x = 0; x < image.width; x++) x < image.width / 2 ? 1.0 : 0.0,
    ];
  }
}

class FixedMasker implements SubjectMasker {
  FixedMasker(this.result);
  final Object result;

  @override
  Future<List<double>> maskFor(String imagePath) async {
    final value = result;
    if (value is Exception || value is Error) throw value;
    return value as List<double>;
  }
}

class FakeInstaller implements SubjectModelInstaller {
  const FakeInstaller(this.status) : failure = null;
  const FakeInstaller.failing(this.failure) : status = SubjectModelStatus.available;

  final SubjectModelStatus status;
  final String? failure;

  @override
  Future<SubjectModelStatus> ensureModel() async {
    final error = failure;
    if (error != null) throw SubjectModelException(error);
    return status;
  }
}

void main() {
  late Directory tempDir;
  late MockProjectRepository repository;

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bg_removal_test_');
    repository = MockProjectRepository();
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Uint8List photo() => Uint8List.fromList(
        img.encodeJpg(img.Image(width: 20, height: 10)..clear(img.ColorRgb8(200, 50, 50))),
      );

  BackgroundRemovalService serviceWith(
    SubjectMasker masker, {
    SubjectModelInstaller installer = const FakeInstaller(SubjectModelStatus.available),
  }) =>
      BackgroundRemovalService(
        projectRepository: repository,
        masker: masker,
        modelInstaller: installer,
        getTempDir: () async => tempDir,
        // Synchronous processing: no isolates in unit tests.
        pixelCutoutProcessor: const SyncCutoutProcessor(),
      );

  test('cutOut keeps the subject and makes the background transparent', () async {
    final masker = LeftHalfMasker();

    final png = await serviceWith(masker).cutOut(photo());

    final cut = img.decodePng(png)!;
    expect(cut.width, 20);
    expect(cut.getPixel(2, 5).a, greaterThan(200), reason: 'subject stays');
    expect(cut.getPixel(17, 5).a, 0, reason: 'background removed');
    // The temporary file handed to ML Kit is cleaned up.
    expect(File(masker.paths.single).existsSync(), isFalse);
  });

  test('an empty mask reports that no subject was found', () async {
    final service = serviceWith(FixedMasker(List<double>.filled(200, 0.0)));

    await expectLater(
      service.cutOut(photo()),
      throwsA(same(BackgroundRemovalException.noSubject)),
    );
  });

  test('a large photo is analysed small but cut out at full size', () async {
    final masker = LeftHalfMasker();
    final big = Uint8List.fromList(
      img.encodeJpg(img.Image(width: 3000, height: 1000)..clear(img.ColorRgb8(20, 200, 20))),
    );

    final cut = img.decodePng(await serviceWith(masker).cutOut(big))!;

    expect(masker.analysedWidths.single, SegmentationInput.maxDimension);
    expect(cut.width, 3000);
    expect(cut.height, 1000);
    expect(cut.getPixel(100, 500).a, greaterThan(200));
    expect(cut.getPixel(2900, 500).a, 0);
  });

  test('while Play services downloads the model, the user is told to wait', () async {
    final service = serviceWith(
      LeftHalfMasker(),
      installer: const FakeInstaller(SubjectModelStatus.installing),
    );

    await expectLater(
      service.cutOut(photo()),
      throwsA(same(BackgroundRemovalException.modelNotReady)),
    );
  });

  test('Play services failures are explained with their details', () async {
    final service = serviceWith(
      LeftHalfMasker(),
      installer: const FakeInstaller.failing('MODEL_INSTALL_FAILED: no Play services'),
    );

    await expectLater(
      service.cutOut(photo()),
      throwsA(isA<BackgroundRemovalException>()
          .having((e) => e.detail, 'detail', 'MODEL_INSTALL_FAILED: no Play services')),
    );
  });

  test('a mask of the wrong size fails with a precise detail', () async {
    final service = serviceWith(FixedMasker(List<double>.filled(7, 1.0)));

    await expectLater(
      service.cutOut(photo()),
      throwsA(isA<BackgroundRemovalException>()
          .having((e) => e.detail, 'detail', contains('mask has 7 values'))),
    );
  });

  test('unexpected errors become a removal failure carrying the cause', () async {
    final service = serviceWith(FixedMasker(StateError('native crash')));

    await expectLater(
      service.cutOut(photo()),
      throwsA(isA<BackgroundRemovalException>()
          .having((e) => e.detail, 'detail', contains('native crash'))),
    );
  });

  test('masker errors such as a missing model are passed on', () async {
    final service = serviceWith(FixedMasker(BackgroundRemovalException.modelNotReady));

    await expectLater(
      service.cutOut(photo()),
      throwsA(same(BackgroundRemovalException.modelNotReady)),
    );
  });

  test('removeBackground saves the cutout into the project as a new layer', () async {
    final source = File('${tempDir.path}/source.jpg')..writeAsBytesSync(photo());
    when(() => repository.saveLayerImage(any(), any(), any()))
        .thenAnswer((inv) async => 'projects/p/images/${inv.positionalArguments[2]}');

    final layer = await serviceWith(LeftHalfMasker())
        .removeBackground(sourceImagePath: source.path, projectId: 'p');

    expect(layer.relativeImagePath, startsWith('projects/p/images/cutout_'));
    expect(layer.relativeImagePath, endsWith('.png'));
  });

  test('removeBackground rejects a missing file', () async {
    await expectLater(
      serviceWith(LeftHalfMasker())
          .removeBackground(sourceImagePath: '${tempDir.path}/nope.jpg', projectId: 'p'),
      throwsArgumentError,
    );
  });
}

/// Runs the cutout on the test isolate.
class SyncCutoutProcessor extends PixelCutoutProcessor {
  const SyncCutoutProcessor();

  @override
  Future<Uint8List> processCutout(CutoutProcessingParams params) async =>
      PixelCutoutProcessor.execute(params);
}
