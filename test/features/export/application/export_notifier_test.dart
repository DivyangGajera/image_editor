import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/export/application/application.dart';
import 'package:image_editor/features/export/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockCanvasExportService extends Mock implements CanvasExportService {}

class FakeGallery implements GallerySaver {
  final List<(Uint8List, String)> saved = [];
  GallerySaveException? failWith;

  @override
  Future<void> save(Uint8List bytes, {required String name}) async {
    if (failWith != null) throw failWith!;
    saved.add((bytes, name));
  }

  @override
  Future<void> openGallery() async {}
}

class FakeProject extends Fake implements ProjectModel {}

class FakeExportConfig extends Fake implements ExportConfig {}

void main() {
  late MockCanvasExportService service;
  late FakeGallery gallery;
  late ProviderContainer container;

  final project = ProjectModel(
    id: 'p',
    title: 'Sale',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

  setUpAll(() {
    registerFallbackValue(FakeProject());
    registerFallbackValue(FakeExportConfig());
  });

  setUp(() {
    service = MockCanvasExportService();
    gallery = FakeGallery();
    container = ProviderContainer(
      overrides: [
        canvasExportServiceProvider.overrideWithValue(service),
        gallerySaverProvider.overrideWithValue(gallery),
      ],
    );
  });

  tearDown(() => container.dispose());

  ExportNotifier notifier() => container.read(exportProvider.notifier);

  test('renders with the given config and saves into the gallery', () async {
    const config = ExportConfig(
      resolution: ExportResolution.fourK,
      watermark: WatermarkConfig(isEnabled: true),
    );
    when(() => service.renderCanvasToBytes(project: any(named: 'project'), config: any(named: 'config')))
        .thenAnswer((_) async => png);

    final ok = await notifier().exportProject(project: project, config: config);

    expect(ok, isTrue);
    verify(() => service.renderCanvasToBytes(project: project, config: config)).called(1);
    expect(gallery.saved.single.$1, png);
    expect(gallery.saved.single.$2, startsWith('Chitred_'));
    expect(container.read(exportProvider).exportedBytes, png);
    expect(container.read(exportProvider).isExporting, isFalse);
  });

  test('a gallery failure surfaces its user-facing message', () async {
    when(() => service.renderCanvasToBytes(project: any(named: 'project'), config: any(named: 'config')))
        .thenAnswer((_) async => png);
    gallery.failWith = const GallerySaveException('Allow access to photos.');

    expect(await notifier().exportProject(project: project, config: const ExportConfig()), isFalse);
    expect(container.read(exportProvider).error, 'Allow access to photos.');
  });

  test('a rendering failure reports a generic message', () async {
    when(() => service.renderCanvasToBytes(project: any(named: 'project'), config: any(named: 'config')))
        .thenThrow(StateError('boom'));

    expect(await notifier().exportProject(project: project, config: const ExportConfig()), isFalse);
    expect(container.read(exportProvider).error, contains('could not be created'));
    expect(gallery.saved, isEmpty);
  });

  test('file names are timestamped under the app name', () {
    expect(ExportNotifier.fileNameFor(DateTime(2026, 11, 5, 9, 3, 7)), 'Chitred_20261105_090307');
  });

  test('clear resets the state', () async {
    when(() => service.renderCanvasToBytes(project: any(named: 'project'), config: any(named: 'config')))
        .thenAnswer((_) async => png);
    await notifier().exportProject(project: project, config: const ExportConfig());

    notifier().clear();

    expect(container.read(exportProvider), const ExportState());
  });
}
