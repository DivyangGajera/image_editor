import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_bootstrap_test_');
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('initialize registers every adapter and opens the projects box', () async {
    await AppBootstrap.initialize(hivePath: tempDir.path);

    expect(Hive.isAdapterRegistered(HiveTypeIds.imageLayer), isTrue);
    expect(Hive.isAdapterRegistered(HiveTypeIds.textLayer), isTrue);
    expect(Hive.isAdapterRegistered(HiveTypeIds.doodleLayer), isTrue);
    expect(Hive.isAdapterRegistered(HiveTypeIds.stickerLayer), isTrue);
    expect(Hive.isAdapterRegistered(HiveTypeIds.projectModel), isTrue);
    expect(Hive.isBoxOpen(StorageKeys.projectsBox), isTrue);
  });

  test('initialize is idempotent', () async {
    await AppBootstrap.initialize(hivePath: tempDir.path);
    await expectLater(
      AppBootstrap.initialize(hivePath: tempDir.path),
      completes,
    );
  });

  test('a project with every layer type survives a close and reopen', () async {
    await AppBootstrap.initialize(hivePath: tempDir.path);

    final createdAt = DateTime(2026, 11, 4, 9, 30);
    final project = ProjectModel(
      id: 'round-trip',
      title: 'Round Trip',
      canvasWidth: 1080.0,
      canvasHeight: 1350.0,
      createdAt: createdAt,
      updatedAt: createdAt,
      layers: const <CanvasLayer>[
        ImageLayer(
          id: 'img',
          x: 0.25,
          y: 0.75,
          scale: 1.5,
          rotation: 0.3,
          relativeImagePath: 'projects/round-trip/images/a.png',
          isFlippedHorizontally: true,
          activeFilter: 'grayscale',
        ),
        TextLayer(
          id: 'txt',
          x: 0.5,
          y: 0.1,
          zIndex: 1,
          text: 'Sale',
          fontFamily: 'Poppins',
          isBold: true,
          boxColorValue: 0xCC000000,
          boxBorderRadius: 12.0,
          shadowColorValue: 0x88000000,
        ),
        DoodleLayer(
          id: 'doodle',
          x: 0.5,
          y: 0.5,
          zIndex: 2,
          points: <List<double>>[
            <double>[0.1, 0.2],
            <double>[0.3, 0.4],
          ],
          hasGlow: true,
        ),
        StickerLayer(
          id: 'sticker',
          x: 0.9,
          y: 0.9,
          zIndex: 3,
          isVisible: false,
          assetPath: 'assets/stickers/badges/badge_bestseller.png',
        ),
      ],
    );

    await Hive.box<ProjectModel>(StorageKeys.projectsBox).put(project.id, project);
    await Hive.close();

    await AppBootstrap.initialize(hivePath: tempDir.path);
    final restored = Hive.box<ProjectModel>(StorageKeys.projectsBox).get(project.id);

    expect(restored, isNotNull);
    expect(restored, equals(project));
    expect(restored!.layers.map((l) => l.runtimeType).toList(), <Type>[
      ImageLayer,
      TextLayer,
      DoodleLayer,
      StickerLayer,
    ]);
  });
}
