import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/export/application/canvas_export_service.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/images/application/image_import_service.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/projects/application/application.dart';
import 'package:image_editor/features/projects/domain/canvas_format.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockImageImportService extends Mock implements ImageImportService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ProjectRepository repository;
  late MockImageImportService imageImport;
  late ProviderContainer container;

  setUpAll(() {
    AppBootstrap.registerAdapters();
    registerFallbackValue(ImageSource.gallery);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('projects_notifier_test_');
    Hive.init(tempDir.path);
    repository = ProjectRepository(
      getBaseDir: () async => tempDir,
      projectsBox: await Hive.openBox<ProjectModel>(StorageKeys.projectsBox),
    );
    imageImport = MockImageImportService();
    container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        imageImportServiceProvider.overrideWithValue(imageImport),
        canvasExportServiceProvider.overrideWithValue(
          CanvasExportService(projectRepository: repository),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  ProjectsNotifier notifier() => container.read(projectsProvider.notifier);
  Future<List<ProjectModel>> projects() => container.read(projectsProvider.future);

  Future<bool> thumbnailExists(String id) async =>
      (await repository.resolveRelativePath(ProjectRepository.thumbnailRelativePath(id)))
          .existsSync();

  test('starts empty and lists projects most recently edited first', () async {
    expect(await projects(), isEmpty);

    final first = await notifier().createBlank(canvasSize: CanvasFormat.square.size);
    final second = await notifier().createBlank(canvasSize: CanvasFormat.story.size);

    expect((await projects()).map((p) => p.id), [second.id, first.id]);
  });

  test('createBlank saves the canvas size and default title and renders a thumbnail',
      () async {
    final project = await notifier().createBlank(canvasSize: CanvasFormat.portrait.size);

    expect(project.title, ProjectsNotifier.defaultTitle);
    expect(project.canvasWidth, 1080);
    expect(project.canvasHeight, 1350);
    expect(await repository.loadProject(project.id), project);
    expect(await thumbnailExists(project.id), isTrue);

    final thumb = img.decodePng(
      await (await repository.resolveRelativePath(
        ProjectRepository.thumbnailRelativePath(project.id),
      ))
          .readAsBytes(),
    )!;
    expect(thumb.height, ProjectThumbnailService.longEdge);
    expect(thumb.width, 384);
  });

  test('createFromPhoto sizes the canvas to the photo and fills it', () async {
    when(() => imageImport.importPhoto(
          source: any(named: 'source'),
          projectId: any(named: 'projectId'),
        )).thenAnswer(
      (invocation) async => ImportedPhoto(
        relativePath:
            'projects/${invocation.namedArguments[#projectId]}/images/photo.jpg',
        width: 2048,
        height: 1536,
        originalPath: 'projects/${invocation.namedArguments[#projectId]}/images/orig.jpg',
      ),
    );

    final project = await notifier().createFromPhoto(ImageSource.gallery);

    expect(project, isNotNull);
    expect(project!.canvasWidth, 1440);
    expect(project.canvasHeight, 1080);
    final layer = project.layers.single as ImageLayer;
    expect(layer.scale, closeTo(1440 / 2048, 1e-9));
    expect(layer.relativeImagePath, 'projects/${project.id}/images/photo.jpg');
    expect(layer.originalImagePath, 'projects/${project.id}/images/orig.jpg');
    expect((await projects()).single.id, project.id);
  });

  test('createFromPhoto creates nothing when the user cancels', () async {
    when(() => imageImport.importPhoto(
          source: any(named: 'source'),
          projectId: any(named: 'projectId'),
        )).thenAnswer((_) async => null);

    expect(await notifier().createFromPhoto(ImageSource.camera), isNull);
    expect(await projects(), isEmpty);
  });

  test('rename trims titles and ignores blank ones', () async {
    final project = await notifier().createBlank(canvasSize: CanvasFormat.square.size);

    await notifier().rename(project.id, '  Diwali Sale  ');
    expect((await projects()).single.title, 'Diwali Sale');

    await notifier().rename(project.id, '   ');
    expect((await projects()).single.title, 'Diwali Sale');
  });

  test('duplicate creates an independent "(copy)" project', () async {
    final project = await notifier().createBlank(
      canvasSize: CanvasFormat.square.size,
      title: 'Flyer',
    );

    final copy = await notifier().duplicate(project.id);

    expect(copy, isNotNull);
    expect(copy!.id, isNot(project.id));
    expect(copy.title, 'Flyer (copy)');
    expect(await projects(), hasLength(2));
    expect(await thumbnailExists(copy.id), isTrue);
  });

  test('delete removes the project, its files and its undo history', () async {
    final project = await notifier().createBlank(canvasSize: CanvasFormat.square.size);
    final history = HistoryManager(projectId: project.id);
    await history.pushState(const CanvasSnapshot(layers: <CanvasLayer>[]));
    await history.dispose();

    await notifier().delete(project.id);

    expect(await projects(), isEmpty);
    expect(await thumbnailExists(project.id), isFalse);
    final reopened = await Hive.openLazyBox<dynamic>(
      HistoryManager.boxNameFor(project.id),
    );
    expect(reopened.isEmpty, isTrue);
  });

  test('onProjectEdited moves the project to the top', () async {
    final older = await notifier().createBlank(canvasSize: CanvasFormat.square.size);
    await notifier().createBlank(canvasSize: CanvasFormat.square.size);

    final edited = (await repository.loadProject(older.id))!
        .copyWith(updatedAt: DateTime.now().add(const Duration(minutes: 1)));
    await repository.saveProject(edited);
    await notifier().onProjectEdited(older.id);

    expect((await projects()).first.id, older.id);
  });

  test('work still running when the provider is disposed completes quietly', () async {
    final project = await notifier().createBlank(canvasSize: CanvasFormat.square.size);

    final pending = notifier().onProjectEdited(project.id);
    container.dispose();

    await expectLater(pending, completes);
    // Recreate so tearDown can dispose a live container.
    container = ProviderContainer(
      overrides: [projectRepositoryProvider.overrideWithValue(repository)],
    );
  });

  test('thumbnail size keeps the canvas aspect ratio', () {
    expect(
      ProjectThumbnailService.thumbnailSize(const Size(1920, 1080)),
      const Size(480, 270),
    );
  });
}
