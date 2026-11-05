import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/segmentation/application/background_removal_service.dart';
import 'package:image_editor/features/segmentation/application/pixel_cutout_processor.dart';
import 'package:mocktail/mocktail.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

/// Marks the left half of the image as the subject.
class LeftHalfMasker implements SubjectMasker {
  final List<String> paths = [];

  @override
  Future<List<double>> maskFor(String imagePath) async {
    paths.add(imagePath);
    final image = img.decodeImage(await File(imagePath).readAsBytes())!;
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
    if (value is Exception) throw value;
    return value as List<double>;
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

  BackgroundRemovalService serviceWith(SubjectMasker masker) => BackgroundRemovalService(
        projectRepository: repository,
        masker: masker,
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
