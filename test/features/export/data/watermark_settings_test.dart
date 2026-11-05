import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/export/application/watermark_settings_notifier.dart';
import 'package:image_editor/features/export/data/watermark_settings_repository.dart';
import 'package:image_editor/features/export/domain/models/watermark_config.dart';
import 'package:image_editor/features/images/application/image_normalizer.dart';

void main() {
  late Directory tempDir;
  late WatermarkSettingsRepository repository;
  late ProviderContainer container;
  Uint8List? nextLogo;

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          watermarkSettingsRepositoryProvider.overrideWithValue(repository),
          logoFileSourceProvider.overrideWithValue(() async => nextLogo),
          logoNormalizerProvider.overrideWithValue(
            (bytes) async => ImageNormalizer.normalize(bytes, maxDimension: maxLogoDimension),
          ),
        ],
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('watermark_settings_test_');
    Hive.init(tempDir.path);
    repository = WatermarkSettingsRepository(
      getBaseDir: () async => tempDir,
      settingsBox: await Hive.openBox<dynamic>(StorageKeys.settingsBox),
    );
    nextLogo = null;
    container = makeContainer();
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  WatermarkSettingsNotifier notifier() => container.read(watermarkSettingsProvider.notifier);
  Future<WatermarkConfig> settings() => container.read(watermarkSettingsProvider.future);

  Uint8List png() => Uint8List.fromList(
        img.encodePng(img.Image(width: 40, height: 20, numChannels: 4)),
      );

  test('starts with the default text watermark', () async {
    expect(await settings(), const WatermarkConfig());
  });

  test('saved settings survive a restart, without the per-export switch', () async {
    await settings();
    await notifier().save(
      const WatermarkConfig(isEnabled: true, text: 'Shree Store', position: WatermarkPosition.center),
    );

    container.dispose();
    container = makeContainer();

    final restored = await settings();
    expect(restored.text, 'Shree Store');
    expect(restored.position, WatermarkPosition.center);
    expect(restored.isEnabled, isFalse);
  });

  test('importLogo stores the picked image under branding/', () async {
    await settings();
    nextLogo = png();

    final path = await notifier().importLogo();

    expect(path, startsWith('branding/logo_'));
    expect(path, endsWith('.png'));
    expect((await repository.resolve(path!)).existsSync(), isTrue);
  });

  test('cancelled or invalid logo picks are handled', () async {
    await settings();
    expect(await notifier().importLogo(), isNull);

    nextLogo = Uint8List.fromList(List<int>.filled(16, 3));
    await expectLater(notifier().importLogo(), throwsA(isA<LogoImportException>()));
  });

  test('replacing the logo deletes the previous file', () async {
    await settings();
    nextLogo = png();
    final first = await notifier().importLogo();
    await notifier().save(const WatermarkConfig(type: WatermarkType.logo).copyWith(logoRelativePath: first));

    final second = await notifier().importLogo();
    await notifier().save((await settings()).copyWith(logoRelativePath: second));

    expect((await repository.resolve(first!)).existsSync(), isFalse);
    expect((await repository.resolve(second!)).existsSync(), isTrue);
    expect((await settings()).logoRelativePath, second);
  });
}
