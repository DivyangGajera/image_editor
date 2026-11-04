import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('ProjectRepository', () {
    late Directory tempBaseDir;
    late Box<ProjectModel> testBox;
    late ProjectRepository repository;
    final testDate = DateTime(2026, 10, 15, 14, 0);

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ImageLayerAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TextLayerAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DoodleLayerAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(StickerLayerAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ProjectModelAdapter());
    });

    setUp(() async {
      tempBaseDir = await Directory.systemTemp.createTemp('project_repo_test_');
      Hive.init(tempBaseDir.path);
      testBox = await Hive.openBox<ProjectModel>(StorageKeys.projectsBox);

      repository = ProjectRepository(
        getBaseDir: () async => tempBaseDir,
        projectsBox: testBox,
      );
    });

    tearDown(() async {
      await testBox.close();
      await Hive.close();
      if (tempBaseDir.existsSync()) {
        await tempBaseDir.delete(recursive: true);
      }
    });

    test('getProjectDirectory resolves sandbox folder and ensures it exists', () async {
      const projectId = 'proj-sandbox-1';
      final dir = await repository.getProjectDirectory(projectId);

      expect(dir.existsSync(), isTrue);
      expect(dir.path, endsWith('projects/$projectId'));
      expect(dir.path.startsWith(tempBaseDir.path), isTrue);
    });

    test('saveLayerImage writes binary data and returns ONLY the relative path', () async {
      const projectId = 'proj-img-1';
      final testBytes = Uint8List.fromList(<int>[137, 80, 78, 71, 13, 10, 26, 10]);
      const filename = 'layer_01.png';

      final relativePath = await repository.saveLayerImage(projectId, testBytes, filename);

      // Verify relative path contract
      expect(relativePath, 'projects/$projectId/images/$filename');
      expect(relativePath.startsWith('/'), isFalse);
      expect(relativePath.contains(tempBaseDir.path), isFalse);

      // Verify file on disk
      final absoluteFile = await repository.resolveRelativePath(relativePath);
      expect(absoluteFile.existsSync(), isTrue);
      expect(await absoluteFile.readAsBytes(), equals(testBytes));
    });

    test('resolveRelativePath maps relative paths to absolute filesystem locations', () async {
      const relativePath = 'projects/p1/images/test.png';
      final resolved = await repository.resolveRelativePath(relativePath);

      expect(resolved.path, '${tempBaseDir.path}/$relativePath');
    });

    test('saveProject stores metadata in Hive and loadProject retrieves it', () async {
      final project = ProjectModel(
        id: 'proj-persist-1',
        title: 'Canvas Artwork',
        canvasWidth: 1080.0,
        canvasHeight: 1920.0,
        layers: const <CanvasLayer>[
          ImageLayer(
            id: 'l-1',
            x: 0.5,
            y: 0.5,
            relativeImagePath: 'projects/proj-persist-1/images/layer_01.png',
          ),
        ],
        createdAt: testDate,
        updatedAt: testDate,
      );

      await repository.saveProject(project);

      final loaded = await repository.loadProject(project.id);
      expect(loaded, isNotNull);
      expect(loaded, equals(project));
      expect(loaded!.layers.first, isA<ImageLayer>());
    });

    test('loadProject returns null for non-existent project', () async {
      final loaded = await repository.loadProject('non-existent-id');
      expect(loaded, isNull);
    });

    test('deleteProject purges Hive record AND project folder from disk', () async {
      const projectId = 'proj-delete-1';
      final project = ProjectModel(
        id: projectId,
        title: 'To Be Deleted',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Save project and an image in its sandbox
      await repository.saveProject(project);
      final dummyBytes = Uint8List.fromList(<int>[1, 2, 3]);
      await repository.saveLayerImage(projectId, dummyBytes, 'del.png');

      final projectDir = await repository.getProjectDirectory(projectId);
      expect(projectDir.existsSync(), isTrue);
      expect(await repository.loadProject(projectId), isNotNull);

      // Execute deletion
      await repository.deleteProject(projectId);

      // Verify Hive record deleted
      expect(await repository.loadProject(projectId), isNull);

      // Verify folder removed from filesystem
      expect(projectDir.existsSync(), isFalse);
    });

    test('getAllProjects returns all projects sorted by updatedAt descending', () async {
      final older = ProjectModel(
        id: 'p-old',
        title: 'Older Project',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );
      final newer = ProjectModel(
        id: 'p-new',
        title: 'Newer Project',
        createdAt: DateTime(2026, 10, 15),
        updatedAt: DateTime(2026, 10, 15),
      );

      await repository.saveProject(older);
      await repository.saveProject(newer);

      final all = await repository.getAllProjects();
      expect(all.length, 2);
      expect(all.first.id, newer.id);
      expect(all.last.id, older.id);
    });

    test('projectRepositoryProvider provides repository instance in Riverpod container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(projectRepositoryProvider);
      expect(repo, isA<ProjectRepository>());
    });

    test('multi-project sandboxing guarantees strict isolation between project directories', () async {
      const projA = 'proj-sandbox-a';
      const projB = 'proj-sandbox-b';

      final bytesA = Uint8List.fromList(<int>[10, 20, 30, 40]);
      final bytesB = Uint8List.fromList(<int>[50, 60, 70, 80]);

      final pathA = await repository.saveLayerImage(projA, bytesA, 'img.png');
      final pathB = await repository.saveLayerImage(projB, bytesB, 'img.png');

      expect(pathA, equals('projects/$projA/images/img.png'));
      expect(pathB, equals('projects/$projB/images/img.png'));

      final fileA = await repository.resolveRelativePath(pathA);
      final fileB = await repository.resolveRelativePath(pathB);

      expect(await fileA.readAsBytes(), equals(bytesA));
      expect(await fileB.readAsBytes(), equals(bytesB));
      expect(fileA.path, isNot(equals(fileB.path)));

      // Deleting projA does NOT affect projB
      await repository.deleteProject(projA);

      expect(await fileA.exists(), isFalse);
      expect(await fileB.exists(), isTrue);
      expect(await fileB.readAsBytes(), equals(bytesB));

      // Clean up projB
      await repository.deleteProject(projB);
      expect(await fileB.exists(), isFalse);
    });

    test('deleteProject handles multi-file directories and idempotent calls cleanly', () async {
      const projMulti = 'proj-multi-files';
      final dummyBytes = Uint8List.fromList(<int>[1, 2, 3]);

      for (int i = 0; i < 5; i++) {
        await repository.saveLayerImage(projMulti, dummyBytes, 'layer_$i.png');
      }

      final dir = await repository.getProjectDirectory(projMulti);
      expect(await dir.exists(), isTrue);
      expect((await dir.list(recursive: true).toList()).length, greaterThanOrEqualTo(5));

      // Delete project
      await repository.deleteProject(projMulti);
      expect(await dir.exists(), isFalse);

      // Idempotent deletion on already-deleted project should succeed without error
      await expectLater(repository.deleteProject(projMulti), completes);
    });

    test('saveThumbnail writes thumbnail.png and returns its relative path', () async {
      final relative = await repository.saveThumbnail('thumb-proj', Uint8List.fromList([1, 2, 3]));

      expect(relative, 'projects/thumb-proj/thumbnail.png');
      expect(relative, ProjectRepository.thumbnailRelativePath('thumb-proj'));
      final file = await repository.resolveRelativePath(relative);
      expect(await file.readAsBytes(), [1, 2, 3]);
    });

    test('duplicateProject copies files and remaps image paths to the new project', () async {
      final imagePath = await repository.saveLayerImage('orig', Uint8List.fromList([9, 9]), 'a.png');
      await repository.saveThumbnail('orig', Uint8List.fromList([7]));
      final original = ProjectModel(
        id: 'orig',
        title: 'Original',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        layers: [
          ImageLayer(
            id: 'img',
            x: 0.5,
            y: 0.5,
            relativeImagePath: imagePath,
            originalImagePath: 'projects/orig/images/original.png',
          ),
          const StickerLayer(id: 's', x: 0.1, y: 0.1, assetPath: 'assets/stickers/badges/b.png'),
          const StickerLayer(
            id: 'mine',
            x: 0.2,
            y: 0.2,
            assetPath: 'stickers/logo.png',
            relativeFilePath: 'projects/orig/images/sticker_logo.png',
          ),
        ],
      );
      await repository.saveProject(original);

      final copy = await repository.duplicateProject(
        original,
        newId: 'copy',
        title: 'Original (copy)',
        now: DateTime(2026, 11, 4),
      );

      expect(copy.id, 'copy');
      expect(copy.title, 'Original (copy)');
      expect(copy.createdAt, DateTime(2026, 11, 4));
      final copiedImage = copy.layers.first as ImageLayer;
      expect(copiedImage.relativeImagePath, 'projects/copy/images/a.png');
      expect(copiedImage.originalImagePath, 'projects/copy/images/original.png');
      expect((copy.layers[1] as StickerLayer).assetPath, 'assets/stickers/badges/b.png');
      expect((copy.layers[1] as StickerLayer).relativeFilePath, isNull);
      expect(
        (copy.layers[2] as StickerLayer).relativeFilePath,
        'projects/copy/images/sticker_logo.png',
      );

      final copiedFile = await repository.resolveRelativePath(copiedImage.relativeImagePath);
      expect(await copiedFile.readAsBytes(), [9, 9]);
      final copiedThumb = await repository.resolveRelativePath(
        ProjectRepository.thumbnailRelativePath('copy'),
      );
      expect(copiedThumb.existsSync(), isTrue);
      expect(await repository.loadProject('copy'), copy);

      // The original is untouched and independent.
      await repository.deleteProject('copy');
      expect((await repository.resolveRelativePath(imagePath)).existsSync(), isTrue);
    });

    test('deleteFile removes an existing file and ignores missing ones', () async {
      final path = await repository.saveLayerImage('del', Uint8List.fromList([1]), 'x.png');

      await repository.deleteFile(path);
      expect((await repository.resolveRelativePath(path)).existsSync(), isFalse);
      await expectLater(repository.deleteFile(path), completes);
    });
  });
}
