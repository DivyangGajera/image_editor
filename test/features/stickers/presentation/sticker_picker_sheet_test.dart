import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/images/application/image_normalizer.dart';
import 'package:image_editor/features/stickers/stickers.dart';

import '../../../helpers/pump_until.dart';

void main() {
  late Directory tempDir;
  late UserStickerRepository repository;
  late ProviderContainer container;
  StickerSelection? result;
  Uint8List? nextPick;

  setUpAll(AppBootstrap.registerAdapters);

  Future<void> setUpStorage() async {
    tempDir = await Directory.systemTemp.createTemp('sticker_picker_test_');
    Hive.init(tempDir.path);
    repository = UserStickerRepository(
      getBaseDir: () async => tempDir,
      stickersBox: await Hive.openBox<UserSticker>(StorageKeys.userStickersBox),
    );
    nextPick = null;
    container = ProviderContainer(
      overrides: [
        userStickerRepositoryProvider.overrideWithValue(repository),
        stickerFileSourceProvider.overrideWithValue(() async => nextPick),
        stickerNormalizerProvider.overrideWithValue(
          (bytes) async => ImageNormalizer.normalize(bytes, maxDimension: maxStickerDimension),
        ),
      ],
    );
    await container.read(userStickersProvider.future);
  }

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<void> openSheet(WidgetTester tester) async {
    result = null;
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await StickerPickerSheet.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapReal(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('starts on My stickers with an import tile and lists bundled categories',
      (tester) async {
    await tester.runAsync(setUpStorage);
    await openSheet(tester);

    expect(find.text('Stickers'), findsOneWidget);
    expect(find.byKey(const ValueKey('import_sticker_tile')), findsOneWidget);
    for (final tab in ['My stickers', 'Discounts', 'Urgency', 'Badges']) {
      expect(find.text(tab), findsOneWidget);
    }
  });

  testWidgets('picking a bundled sticker returns it', (tester) async {
    await tester.runAsync(setUpStorage);
    await openSheet(tester);

    await tester.tap(find.text('Discounts'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sticker_thumbnail_discount_bogo')));
    await tester.pumpAndSettle();

    final selection = result! as BundledStickerSelection;
    expect(selection.item.assetPath, 'assets/stickers/discounts/discount_bogo.png');
  });

  testWidgets('imported stickers appear in My stickers and can be picked', (tester) async {
    await tester.runAsync(setUpStorage);
    await openSheet(tester);

    nextPick = Uint8List.fromList(img.encodePng(img.Image(width: 30, height: 20, numChannels: 4)));
    await tapReal(tester, find.byKey(const ValueKey('import_sticker_tile')));
    await pumpUntil(
      tester,
      () => container.read(userStickersProvider).value?.isNotEmpty ?? false,
    );

    final sticker = container.read(userStickersProvider).value!.single;
    await tester.tap(find.byKey(ValueKey('user_sticker_${sticker.id}')));
    await tester.pumpAndSettle();

    expect((result! as UserStickerSelection).sticker, sticker);
  });

  testWidgets('long-press removes a sticker after confirmation', (tester) async {
    await tester.runAsync(() async {
      await setUpStorage();
      await repository.save(
        bytes: Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 4))),
        extension: 'png',
        width: 4,
        height: 4,
      );
      container.invalidate(userStickersProvider);
      await container.read(userStickersProvider.future);
    });
    await openSheet(tester);
    final sticker = container.read(userStickersProvider).value!.single;

    // Start the long-press in the real zone: the delete it leads to performs
    // real Hive and file I/O, which cannot finish inside the fake-async zone.
    await tester.runAsync(() async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey('user_sticker_${sticker.id}'))),
      );
      await Future<void>.delayed(kLongPressTimeout + const Duration(milliseconds: 200));
      await gesture.up();
    });
    await tester.pumpAndSettle();
    expect(find.text('Remove sticker?'), findsOneWidget);
    await tapReal(tester, find.byKey(const ValueKey('confirm_delete_sticker')));

    await pumpUntil(tester, () => container.read(userStickersProvider).value?.isEmpty ?? false);
  });
}
