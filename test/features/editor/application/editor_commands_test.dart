import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/editor/application/application.dart';
import 'package:image_editor/features/history/history.dart';
import 'package:image_editor/features/images/application/image_import_service.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:image_editor/features/segmentation/application/background_removal_service.dart';
import 'package:image_editor/features/segmentation/application/segmentation_notifier.dart';
import 'package:image_editor/features/stickers/stickers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockImageImportService extends Mock implements ImageImportService {}

class MockBackgroundRemovalService extends Mock implements BackgroundRemovalService {}

void main() {
  late Directory tempDir;
  late ProjectRepository repository;
  late HistoryManager historyManager;
  late MockImageImportService imageImport;
  late MockBackgroundRemovalService backgroundRemoval;
  late ProviderContainer container;
  late EditorCommands commands;

  const projectId = 'editor-commands';
  final project = ProjectModel(
    id: projectId,
    title: 'Commands',
    canvasWidth: 1000.0,
    canvasHeight: 1250.0,
    createdAt: DateTime(2026, 11, 4),
    updatedAt: DateTime(2026, 11, 4),
  );

  setUpAll(() {
    AppBootstrap.registerAdapters();
    registerFallbackValue(ImageSource.gallery);
    registerFallbackValue(Size.zero);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('editor_commands_test_');
    Hive.init(tempDir.path);
    repository = ProjectRepository(
      getBaseDir: () async => tempDir,
      projectsBox: await Hive.openBox<ProjectModel>(StorageKeys.projectsBox),
    );
    await repository.saveProject(project);
    historyManager = HistoryManager(
      projectId: projectId,
      historyBox: await Hive.openLazyBox<dynamic>(HistoryManager.boxNameFor(projectId)),
    );
    imageImport = MockImageImportService();
    backgroundRemoval = MockBackgroundRemovalService();

    container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        historyManagerProvider(projectId).overrideWithValue(historyManager),
        backgroundRemovalServiceProvider.overrideWithValue(backgroundRemoval),
      ],
    );
    container.listen(canvasProvider(projectId), (_, _) {});
    container.listen(segmentationProvider, (_, _) {});
    await container.read(canvasProvider(projectId).future);

    commands = EditorCommands(
      projectId: projectId,
      canvas: () => container.read(canvasProvider(projectId).notifier),
      canvasState: () => container.read(canvasProvider(projectId)).requireValue,
      imageImport: imageImport,
      segmentation: () => container.read(segmentationProvider.notifier),
      projectRepository: repository,
      userStickers: UserStickerRepository(getBaseDir: () async => tempDir),
      readAssetSize: (_) async => const Size(500, 200),
    );
  });

  tearDown(() async {
    container.dispose();
    await historyManager.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  List<CanvasLayer> layers() =>
      container.read(canvasProvider(projectId)).requireValue.project.layers;

  const imported = ImportedPhoto(
    relativePath: 'projects/editor-commands/images/img_a.jpg',
    originalPath: 'projects/editor-commands/images/orig_a.jpg',
    width: 2000,
    height: 1000,
  );

  test('importPhoto imports into this project', () async {
    when(() => imageImport.importPhoto(
          source: any(named: 'source'),
          projectId: any(named: 'projectId'),
        )).thenAnswer((_) async => imported);

    expect(await commands.importPhoto(ImageSource.camera), imported);
    verify(() => imageImport.importPhoto(source: ImageSource.camera, projectId: projectId))
        .called(1);
  });

  test('addImportedPhoto fits the photo to the canvas and keeps its original', () async {
    await commands.addImportedPhoto(imported);

    final layer = layers().single as ImageLayer;
    expect(layer.relativeImagePath, imported.relativePath);
    expect(layer.originalImagePath, imported.originalPath);
    // Width-limited: 1000 * 0.7 / 2000.
    expect(layer.scale, closeTo(0.35, 1e-9));
  });

  test('addImportedPhoto with a cut-out saves and uses it instead', () async {
    await commands.addImportedPhoto(imported, cutoutPng: Uint8List.fromList([1, 2, 3]));

    final layer = layers().single as ImageLayer;
    expect(layer.relativeImagePath, startsWith('projects/editor-commands/images/cutout_'));
    expect(layer.relativeImagePath, endsWith('.png'));
    expect(layer.originalImagePath, isNull, reason: 'the cut-out crops on its own');
    expect(
      await (await repository.resolveRelativePath(layer.relativeImagePath)).readAsBytes(),
      [1, 2, 3],
    );
  });

  test('addText scales text relative to a phone-width canvas', () async {
    await commands.addText(const TextLayer(id: 't', x: 0.5, y: 0.5, text: 'Hello'));

    expect(layers().single.scale, closeTo(1000 / 360, 1e-9));
  });

  test('addSticker sizes a bundled sticker to 35% of the canvas width', () async {
    await commands.addSticker(
      const BundledStickerSelection(
        StickerItem(id: 'x', title: 'X', assetPath: 'assets/stickers/x.png', category: 'C'),
      ),
    );

    final layer = layers().single as StickerLayer;
    // 1000 * 0.35 / 500 px asset width.
    expect(layer.scale, closeTo(0.7, 1e-9));
    expect(layer.assetPath, 'assets/stickers/x.png');
    expect(layer.isUserSticker, isFalse);
  });

  test('addSticker copies a user sticker into the project', () async {
    final libraryFile = File('${tempDir.path}/stickers/logo.png');
    await libraryFile.parent.create(recursive: true);
    await libraryFile.writeAsBytes([1, 2, 3]);

    await commands.addSticker(
      UserStickerSelection(
        UserSticker(
          id: 'logo',
          relativePath: 'stickers/logo.png',
          width: 250,
          height: 100,
          addedAt: DateTime(2026),
        ),
      ),
    );

    final layer = layers().single as StickerLayer;
    expect(layer.isUserSticker, isTrue);
    expect(layer.relativeFilePath, startsWith('projects/editor-commands/images/sticker_'));
    expect(layer.relativeFilePath, endsWith('.png'));
    expect(layer.scale, closeTo(1000 * 0.35 / 250, 1e-9));
    final copy = await repository.resolveRelativePath(layer.relativeFilePath!);
    expect(await copy.readAsBytes(), [1, 2, 3]);
  });

  test('removeBackground runs segmentation on the resolved file and applies the cutout',
      () async {
    await container.read(canvasProvider(projectId).notifier).addLayer(
          const ImageLayer(
            id: 'photo',
            x: 0.4,
            y: 0.4,
            relativeImagePath: 'projects/editor-commands/images/a.jpg',
          ),
        );
    when(() => backgroundRemoval.removeBackground(
          sourceImagePath: any(named: 'sourceImagePath'),
          projectId: any(named: 'projectId'),
        )).thenAnswer(
      (_) async => const ImageLayer(
        id: 'cutout',
        x: 0.5,
        y: 0.5,
        relativeImagePath: 'projects/editor-commands/images/cutout.png',
      ),
    );

    final done = await commands.removeBackground('photo');

    expect(done, isTrue);
    expect(layers().map((l) => l.id), <String>['photo', 'cutout']);
    expect(layers().first.isVisible, isFalse);
    verify(() => backgroundRemoval.removeBackground(
          sourceImagePath: '${tempDir.path}/projects/editor-commands/images/a.jpg',
          projectId: projectId,
        )).called(1);
  });

  test('removeBackground ignores layers that are not images', () async {
    await container
        .read(canvasProvider(projectId).notifier)
        .addLayer(const TextLayer(id: 't', x: 0.5, y: 0.5, text: 'Hi'));

    expect(await commands.removeBackground('t'), isFalse);
    verifyNever(() => backgroundRemoval.removeBackground(
          sourceImagePath: any(named: 'sourceImagePath'),
          projectId: any(named: 'projectId'),
        ));
  });

  test('commands obtained from the provider still work after an async gap', () async {
    // The editor reads editorCommandsProvider without listening to it and then
    // awaits the photo picker and cropper before touching the canvas.
    final providerContainer = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        historyManagerProvider(projectId).overrideWithValue(historyManager),
        imageImportServiceProvider.overrideWithValue(imageImport),
      ],
    );
    addTearDown(providerContainer.dispose);
    providerContainer.listen(canvasProvider(projectId), (_, _) {});
    await providerContainer.read(canvasProvider(projectId).future);

    when(() => imageImport.importPhoto(
          source: any(named: 'source'),
          projectId: any(named: 'projectId'),
        )).thenAnswer((_) async {
      // The user spends time in the picker and cropper.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return imported;
    });

    final commands = providerContainer.read(editorCommandsProvider(projectId));
    final photo = await commands.importPhoto(ImageSource.gallery);
    // ...and then in the background-removal prompt.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await commands.addImportedPhoto(photo!);
    expect(
      providerContainer.read(canvasProvider(projectId)).requireValue.project.layers.single,
      isA<ImageLayer>(),
    );
  });

  test('a bundled sticker added through the provider lands on the canvas', () async {
    final providerContainer = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        historyManagerProvider(projectId).overrideWithValue(historyManager),
      ],
    );
    addTearDown(providerContainer.dispose);
    providerContainer.listen(canvasProvider(projectId), (_, _) {});
    await providerContainer.read(canvasProvider(projectId).future);

    // Reads the real bundled asset (an async gap) before adding the layer.
    await providerContainer.read(editorCommandsProvider(projectId)).addSticker(
          const BundledStickerSelection(
            StickerItem(
              id: 'discount_bogo',
              title: 'BOGO',
              assetPath: 'assets/stickers/discounts/discount_bogo.png',
              category: 'Discounts',
            ),
          ),
        );

    final layer = providerContainer
        .read(canvasProvider(projectId))
        .requireValue
        .project
        .layers
        .single as StickerLayer;
    expect(layer.assetPath, 'assets/stickers/discounts/discount_bogo.png');
    expect(layer.scale, greaterThan(0));
  });

  group('cropping', () {
    const cropped = ImageLayer(
      id: 'photo',
      x: 0.4,
      y: 0.6,
      scale: 0.5,
      rotation: 0.3,
      activeFilter: 'grayscale',
      relativeImagePath: 'projects/editor-commands/images/img_1.jpg',
      originalImagePath: 'projects/editor-commands/images/orig_1.jpg',
    );

    setUp(() async {
      await container.read(canvasProvider(projectId).notifier).addLayer(cropped);
    });

    test('cropImage re-crops from the original and keeps the transform and filter',
        () async {
      when(() => imageImport.recrop(
            projectId: any(named: 'projectId'),
            originalPath: any(named: 'originalPath'),
          )).thenAnswer(
        (_) async => const ImportedPhoto(
          relativePath: 'projects/editor-commands/images/img_2.jpg',
          width: 300,
          height: 200,
          originalPath: 'projects/editor-commands/images/orig_1.jpg',
        ),
      );

      expect(await commands.cropImage('photo'), isTrue);

      verify(() => imageImport.recrop(
            projectId: projectId,
            originalPath: 'projects/editor-commands/images/orig_1.jpg',
          )).called(1);
      final layer = layers().single as ImageLayer;
      expect(layer.relativeImagePath, 'projects/editor-commands/images/img_2.jpg');
      expect(layer.originalImagePath, 'projects/editor-commands/images/orig_1.jpg');
      expect(layer.x, 0.4);
      expect(layer.scale, 0.5);
      expect(layer.rotation, 0.3);
      expect(layer.activeFilter, 'grayscale');
    });

    test('cropImage leaves the layer alone when the user cancels', () async {
      when(() => imageImport.recrop(
            projectId: any(named: 'projectId'),
            originalPath: any(named: 'originalPath'),
          )).thenAnswer((_) async => null);

      expect(await commands.cropImage('photo'), isFalse);
      expect(layers().single, cropped.copyWith(zIndex: 0));
    });

    test('resetCrop restores the original and can be undone', () async {
      await commands.resetCrop('photo');

      final layer = layers().single as ImageLayer;
      expect(layer.relativeImagePath, 'projects/editor-commands/images/orig_1.jpg');
      expect(layer.isCropped, isFalse);

      await container.read(canvasProvider(projectId).notifier).undo();
      expect((layers().single as ImageLayer).isCropped, isTrue);
    });
  });

  group('EditorUiNotifier', () {
    test('switches modes and clamps the brush width', () {
      final provider = editorUiProvider(projectId);
      container.listen(provider, (_, _) {});
      final notifier = container.read(provider.notifier);

      notifier.toggleFilterStrip();
      expect(container.read(provider).isFilterStripOpen, isTrue);

      notifier.enterDrawMode();
      expect(container.read(provider).mode, EditorMode.draw);
      expect(container.read(provider).isFilterStripOpen, isFalse);

      notifier.setDrawStrokeWidth(500);
      expect(container.read(provider).drawStrokeWidth, EditorUiState.maxStrokeWidth);
      notifier.setDrawStrokeWidth(0);
      expect(container.read(provider).drawStrokeWidth, EditorUiState.minStrokeWidth);

      notifier.toggleDrawGlow();
      notifier.setDrawColor(0xFF00FF00);
      expect(container.read(provider).drawGlow, isTrue);
      expect(container.read(provider).drawColorValue, 0xFF00FF00);

      notifier.exitDrawMode();
      expect(container.read(provider).mode, EditorMode.select);
    });
  });
}
