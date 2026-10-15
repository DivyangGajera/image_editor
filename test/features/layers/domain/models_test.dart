import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

void main() {
  group('Layers Domain Models', () {
    late Directory tempDir;

    setUpAll(() {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ImageLayerAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TextLayerAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DoodleLayerAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(StickerLayerAdapter());
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_layers_test_');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('ImageLayer', () {
      const initialLayer = ImageLayer(
        id: 'img-1',
        x: 0.5,
        y: 0.5,
        scale: 1.2,
        rotation: 0.785,
        zIndex: 1,
        isVisible: true,
        relativeImagePath: 'projects/p1/images/layer_1.png',
        isFlippedHorizontally: false,
        activeFilter: 'grayscale',
        cropRect: <double>[0.1, 0.1, 0.9, 0.9],
      );

      test('instantiates with expected properties and defaults', () {
        const defaultLayer = ImageLayer(
          id: 'img-default',
          x: 0.2,
          y: 0.3,
          relativeImagePath: 'projects/p1/images/img.png',
        );

        expect(defaultLayer.id, 'img-default');
        expect(defaultLayer.x, 0.2);
        expect(defaultLayer.y, 0.3);
        expect(defaultLayer.scale, 1.0);
        expect(defaultLayer.rotation, 0.0);
        expect(defaultLayer.zIndex, 0);
        expect(defaultLayer.isVisible, isTrue);
        expect(defaultLayer.isFlippedHorizontally, isFalse);
        expect(defaultLayer.activeFilter, isNull);
        expect(defaultLayer.cropRect, isNull);
      });

      test('copyWith preserves unchanged values and replaces updated ones', () {
        final updated = initialLayer.copyWith(
          x: 0.8,
          scale: 2.0,
          isFlippedHorizontally: true,
          cropRect: <double>[0.0, 0.0, 1.0, 1.0],
        );

        expect(updated.id, initialLayer.id);
        expect(updated.x, 0.8);
        expect(updated.y, initialLayer.y);
        expect(updated.scale, 2.0);
        expect(updated.rotation, initialLayer.rotation);
        expect(updated.isFlippedHorizontally, isTrue);
        expect(updated.activeFilter, initialLayer.activeFilter);
        expect(updated.cropRect, <double>[0.0, 0.0, 1.0, 1.0]);
      });

      test('equality and hashCode contract', () {
        final duplicate = initialLayer.copyWith();
        final different = initialLayer.copyWith(scale: 3.5);

        expect(initialLayer, equals(duplicate));
        expect(initialLayer.hashCode, equals(duplicate.hashCode));
        expect(initialLayer, isNot(equals(different)));
      });

      test('serializes and deserializes accurately with Hive CE', () async {
        final box = await Hive.openBox<CanvasLayer>('image_layer_box');
        await box.put(initialLayer.id, initialLayer);

        final retrieved = box.get(initialLayer.id);
        expect(retrieved, isA<ImageLayer>());
        expect(retrieved, equals(initialLayer));
        final retrievedImg = retrieved! as ImageLayer;
        expect(retrievedImg.relativeImagePath, initialLayer.relativeImagePath);
        expect(retrievedImg.activeFilter, 'grayscale');
        expect(retrievedImg.cropRect, <double>[0.1, 0.1, 0.9, 0.9]);
      });
    });

    group('TextLayer', () {
      const initialLayer = TextLayer(
        id: 'txt-1',
        x: 0.4,
        y: 0.6,
        text: 'Hello World',
        fontFamily: 'Inter',
        isCustomFont: true,
        customFontPath: 'projects/p1/fonts/custom.ttf',
        textColorValue: 0xFFFF5722,
        fontSize: 32.0,
        isBold: true,
        isItalic: true,
        boxColorValue: 0x88000000,
        boxBorderRadius: 8.0,
        shadowColorValue: 0xFF000000,
      );

      test('instantiates with expected default values', () {
        const defaultLayer = TextLayer(
          id: 'txt-def',
          x: 0.5,
          y: 0.5,
          text: 'Default',
        );

        expect(defaultLayer.fontFamily, 'Roboto');
        expect(defaultLayer.isCustomFont, isFalse);
        expect(defaultLayer.customFontPath, isNull);
        expect(defaultLayer.textColorValue, 0xFFFFFFFF);
        expect(defaultLayer.fontSize, 24.0);
        expect(defaultLayer.isBold, isFalse);
        expect(defaultLayer.isItalic, isFalse);
        expect(defaultLayer.boxColorValue, isNull);
        expect(defaultLayer.boxBorderRadius, 0.0);
        expect(defaultLayer.shadowColorValue, isNull);
      });

      test('copyWith updates specified fields only', () {
        final updated = initialLayer.copyWith(
          text: 'Updated Text',
          fontSize: 48.0,
          isBold: false,
        );

        expect(updated.text, 'Updated Text');
        expect(updated.fontSize, 48.0);
        expect(updated.isBold, isFalse);
        expect(updated.id, initialLayer.id);
        expect(updated.fontFamily, initialLayer.fontFamily);
        expect(updated.customFontPath, initialLayer.customFontPath);
        expect(updated.boxColorValue, initialLayer.boxColorValue);
      });

      test('equality and hashCode contract', () {
        final duplicate = initialLayer.copyWith();
        final different = initialLayer.copyWith(text: 'Changed');

        expect(initialLayer, equals(duplicate));
        expect(initialLayer.hashCode, equals(duplicate.hashCode));
        expect(initialLayer, isNot(equals(different)));
      });

      test('serializes and deserializes accurately with Hive CE', () async {
        final box = await Hive.openBox<CanvasLayer>('text_layer_box');
        await box.put(initialLayer.id, initialLayer);

        final retrieved = box.get(initialLayer.id);
        expect(retrieved, isA<TextLayer>());
        expect(retrieved, equals(initialLayer));
      });
    });

    group('DoodleLayer', () {
      const initialLayer = DoodleLayer(
        id: 'doodle-1',
        x: 0.5,
        y: 0.5,
        points: <List<double>>[
          <double>[0.1, 0.2],
          <double>[0.3, 0.4],
          <double>[0.5, 0.6],
        ],
        strokeColorValue: 0xFF00FF00,
        strokeWidth: 8.0,
        hasGlow: true,
      );

      test('instantiates with expected default values', () {
        const defaultLayer = DoodleLayer(
          id: 'doodle-def',
          x: 0.1,
          y: 0.1,
          points: <List<double>>[],
        );

        expect(defaultLayer.strokeColorValue, 0xFFFF0000);
        expect(defaultLayer.strokeWidth, 5.0);
        expect(defaultLayer.hasGlow, isFalse);
      });

      test('copyWith updates specified fields and deeply copies points', () {
        final updated = initialLayer.copyWith(
          strokeWidth: 12.0,
          hasGlow: false,
        );

        expect(updated.strokeWidth, 12.0);
        expect(updated.hasGlow, isFalse);
        expect(updated.points.length, 3);
        expect(updated.points[0], <double>[0.1, 0.2]);
      });

      test('equality handles nested point comparison', () {
        final duplicate = initialLayer.copyWith();
        final differentPoints = initialLayer.copyWith(
          points: <List<double>>[
            <double>[0.9, 0.9],
          ],
        );

        expect(initialLayer, equals(duplicate));
        expect(initialLayer.hashCode, equals(duplicate.hashCode));
        expect(initialLayer, isNot(equals(differentPoints)));
      });

      test('serializes and deserializes accurately with Hive CE', () async {
        final box = await Hive.openBox<CanvasLayer>('doodle_layer_box');
        await box.put(initialLayer.id, initialLayer);

        final retrieved = box.get(initialLayer.id);
        expect(retrieved, isA<DoodleLayer>());
        expect(retrieved, equals(initialLayer));
      });
    });

    group('StickerLayer', () {
      const initialLayer = StickerLayer(
        id: 'sticker-1',
        x: 0.2,
        y: 0.8,
        scale: 0.9,
        rotation: 0.1,
        assetPath: 'assets/stickers/star.png',
      );

      test('copyWith updates fields correctly', () {
        final updated = initialLayer.copyWith(
          assetPath: 'assets/stickers/heart.png',
          scale: 1.5,
        );

        expect(updated.assetPath, 'assets/stickers/heart.png');
        expect(updated.scale, 1.5);
        expect(updated.id, initialLayer.id);
      });

      test('equality and hashCode contract', () {
        final duplicate = initialLayer.copyWith();
        final different = initialLayer.copyWith(assetPath: 'assets/other.png');

        expect(initialLayer, equals(duplicate));
        expect(initialLayer.hashCode, equals(duplicate.hashCode));
        expect(initialLayer, isNot(equals(different)));
      });

      test('serializes and deserializes accurately with Hive CE', () async {
        final box = await Hive.openBox<CanvasLayer>('sticker_layer_box');
        await box.put(initialLayer.id, initialLayer);

        final retrieved = box.get(initialLayer.id);
        expect(retrieved, isA<StickerLayer>());
        expect(retrieved, equals(initialLayer));
      });
    });
  });
}
