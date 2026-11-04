import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/images/application/image_normalizer.dart';
import 'package:image_editor/features/stickers/stickers.dart';

void main() {
  late Directory tempDir;
  late UserStickerRepository repository;
  late ProviderContainer container;
  Uint8List? nextPick;

  setUpAll(AppBootstrap.registerAdapters);

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          userStickerRepositoryProvider.overrideWithValue(repository),
          stickerFileSourceProvider.overrideWithValue(() async => nextPick),
          stickerNormalizerProvider.overrideWithValue(
            (bytes) async => ImageNormalizer.normalize(bytes, maxDimension: maxStickerDimension),
          ),
        ],
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('user_stickers_test_');
    Hive.init(tempDir.path);
    repository = UserStickerRepository(
      getBaseDir: () async => tempDir,
      stickersBox: await Hive.openBox<UserSticker>(StorageKeys.userStickersBox),
    );
    nextPick = null;
    container = makeContainer();
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  UserStickersNotifier notifier() => container.read(userStickersProvider.notifier);
  Future<List<UserSticker>> stickers() => container.read(userStickersProvider.future);

  Uint8List transparentPng(int width, int height) {
    final image = img.Image(width: width, height: height, numChannels: 4)
      ..clear(img.ColorRgba8(0, 0, 0, 0));
    image.setPixel(1, 1, img.ColorRgba8(255, 0, 0, 255));
    return Uint8List.fromList(img.encodePng(image));
  }

  test('imports a picked image as a transparent, size-limited sticker', () async {
    await stickers();
    nextPick = transparentPng(2000, 1000);

    final sticker = await notifier().importFromDevice();

    expect(sticker, isNotNull);
    expect(sticker!.relativePath, startsWith('stickers/'));
    expect(sticker.relativePath, endsWith('.png'), reason: 'transparency is kept');
    expect(sticker.width, maxStickerDimension);
    expect(sticker.height, 512);
    expect((await repository.resolve(sticker.relativePath)).existsSync(), isTrue);
    expect((await stickers()).single, sticker);
  });

  test('cancelling the picker imports nothing', () async {
    await stickers();
    expect(await notifier().importFromDevice(), isNull);
    expect(await stickers(), isEmpty);
  });

  test('a file that is not an image is rejected', () async {
    await stickers();
    nextPick = Uint8List.fromList(List<int>.filled(32, 7));

    await expectLater(notifier().importFromDevice(), throwsA(isA<StickerImportException>()));
    expect(await stickers(), isEmpty);
  });

  test('stickers persist across restarts, newest first, and can be deleted', () async {
    await stickers();
    nextPick = transparentPng(20, 20);
    final first = await notifier().importFromDevice();
    final second = await notifier().importFromDevice();

    container.dispose();
    container = makeContainer();
    expect((await stickers()).map((s) => s.id), [second!.id, first!.id]);

    await notifier().delete(first);
    expect((await stickers()).single.id, second.id);
    expect((await repository.resolve(first.relativePath)).existsSync(), isFalse);
  });
}
