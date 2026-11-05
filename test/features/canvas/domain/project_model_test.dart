import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('ProjectModel', () {
    late Directory tempDir;
    final testDate = DateTime(2026, 10, 15, 12, 0);

    setUpAll(AppBootstrap.registerAdapters);

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_canvas_test_');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('instantiates with expected default canvas dimensions and empty layers', () {
      final project = ProjectModel(
        id: 'proj-1',
        title: 'New Artwork',
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(project.id, 'proj-1');
      expect(project.title, 'New Artwork');
      expect(project.canvasWidth, AppConstants.defaultCanvasWidth);
      expect(project.canvasHeight, AppConstants.defaultCanvasHeight);
      expect(project.layers, isEmpty);
      expect(project.createdAt, testDate);
      expect(project.updatedAt, testDate);
    });

    test('copyWith updates specified fields correctly', () {
      final project = ProjectModel(
        id: 'proj-1',
        title: 'Original Title',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final updatedDate = DateTime(2026, 10, 15, 13, 30);
      const newLayer = StickerLayer(
        id: 'stk-1',
        x: 0.5,
        y: 0.5,
        assetPath: 'assets/stickers/badge.png',
      );

      final updated = project.copyWith(
        title: 'Updated Title',
        canvasWidth: 800.0,
        canvasHeight: 600.0,
        layers: <CanvasLayer>[newLayer],
        updatedAt: updatedDate,
      );

      expect(updated.id, 'proj-1');
      expect(updated.title, 'Updated Title');
      expect(updated.canvasWidth, 800.0);
      expect(updated.canvasHeight, 600.0);
      expect(updated.layers.length, 1);
      expect(updated.layers.first, equals(newLayer));
      expect(updated.createdAt, testDate);
      expect(updated.updatedAt, updatedDate);
    });

    test('equality and hashCode contract', () {
      final projectA = ProjectModel(
        id: 'proj-1',
        title: 'Project A',
        layers: const <CanvasLayer>[
          StickerLayer(id: 's1', x: 0.1, y: 0.1, assetPath: 'assets/s1.png'),
        ],
        createdAt: testDate,
        updatedAt: testDate,
      );

      final projectB = projectA.copyWith();
      final projectC = projectA.copyWith(title: 'Different Title');

      expect(projectA, equals(projectB));
      expect(projectA.hashCode, equals(projectB.hashCode));
      expect(projectA, isNot(equals(projectC)));
    });

    test('serializes and deserializes polymorphic layer lists accurately with Hive CE', () async {
      final fullProject = ProjectModel(
        id: 'proj-poly-1',
        title: 'Multi-layer Masterpiece',
        canvasWidth: 1080.0,
        canvasHeight: 1080.0,
        layers: const <CanvasLayer>[
          ImageLayer(
            id: 'l-img',
            x: 0.5,
            y: 0.5,
            relativeImagePath: 'projects/proj-poly-1/images/bg.png',
            activeFilter: 'vintage',
          ),
          TextLayer(
            id: 'l-txt',
            x: 0.5,
            y: 0.2,
            text: 'Heading',
            fontSize: 40.0,
            textColorValue: 0xFFFFFFFF,
          ),
          DoodleLayer(
            id: 'l-doodle',
            x: 0.5,
            y: 0.5,
            points: <List<double>>[
              <double>[0.0, 0.0],
              <double>[1.0, 1.0],
            ],
            strokeWidth: 4.0,
          ),
          StickerLayer(
            id: 'l-sticker',
            x: 0.8,
            y: 0.8,
            assetPath: 'assets/stickers/star.png',
          ),
        ],
        createdAt: testDate,
        updatedAt: testDate,
      );

      final box = await Hive.openBox<ProjectModel>('projects_test_box');
      await box.put(fullProject.id, fullProject);

      final retrieved = box.get(fullProject.id);
      expect(retrieved, isNotNull);
      expect(retrieved, equals(fullProject));
      expect(retrieved!.layers.length, 4);
      expect(retrieved.layers[0], isA<ImageLayer>());
      expect(retrieved.layers[1], isA<TextLayer>());
      expect(retrieved.layers[2], isA<DoodleLayer>());
      expect(retrieved.layers[3], isA<StickerLayer>());
    });
  });
}
