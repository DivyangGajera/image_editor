import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/fonts/application/application.dart';
import 'package:image_editor/features/fonts/data/data.dart';
import 'package:image_editor/features/fonts/domain/domain.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

/// Serves a stylesheet for any family and the font file for gstatic URLs.
class FakeFontServer implements HttpGetter {
  bool online = true;
  final List<Uri> requested = <Uri>[];
  Completer<void>? gate;

  static final Uint8List ttf =
      Uint8List.fromList([0x00, 0x01, 0x00, 0x00, ...List<int>.filled(96, 3)]);

  @override
  Future<HttpGetResponse> get(
    Uri url, {
    Map<String, String> headers = const {},
    required Duration timeout,
    ProgressCallback? onProgress,
  }) async {
    requested.add(url);
    if (!online) throw const SocketException('offline');
    if (url.host == 'fonts.googleapis.com') {
      return HttpGetResponse(
        200,
        Uint8List.fromList(
          "@font-face { src: url(https://fonts.gstatic.com/s/x/1.ttf) format('truetype'); }"
              .codeUnits,
        ),
      );
    }
    await gate?.future;
    onProgress?.call(ttf.length ~/ 2, ttf.length);
    onProgress?.call(ttf.length, ttf.length);
    return HttpGetResponse(200, ttf);
  }
}

void main() {
  late Directory tempDir;
  late FontRepository fonts;
  late ProjectRepository projects;
  late FakeFontServer server;
  late List<String> registered;
  late ProviderContainer container;

  const catalogFont = CatalogFont('Hind Vadodara', FontCategory.sans, FontScript.gujarati);
  final otf = Uint8List.fromList(['O'.codeUnitAt(0), 'T'.codeUnitAt(0), 'T'.codeUnitAt(0),
      'O'.codeUnitAt(0), ...List<int>.filled(60, 1)]);

  setUpAll(AppBootstrap.registerAdapters);

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          fontRepositoryProvider.overrideWithValue(fonts),
          projectRepositoryProvider.overrideWithValue(projects),
          googleFontsClientProvider.overrideWithValue(GoogleFontsClient(http: server)),
          fontRegistrarProvider.overrideWithValue((bytes, family) async => registered.add(family)),
        ],
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('font_library_test_');
    Hive.init(tempDir.path);
    fonts = FontRepository(
      getBaseDir: () async => tempDir,
      fontsBox: await Hive.openBox<FontEntry>(StorageKeys.fontsBox),
    );
    projects = ProjectRepository(
      getBaseDir: () async => tempDir,
      projectsBox: await Hive.openBox<ProjectModel>(StorageKeys.projectsBox),
    );
    server = FakeFontServer();
    registered = <String>[];
    container = makeContainer();
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  FontLibraryNotifier library() => container.read(fontLibraryProvider.notifier);
  Future<FontLibraryState> state() => container.read(fontLibraryProvider.future);

  test('starts with only the built-in default installed', () async {
    final initial = await state();
    expect(initial.fonts, isEmpty);
    expect(initial.isInstalled(systemDefaultFontFamily), isTrue);
    expect(initial.isInstalled('Hind Vadodara'), isFalse);
  });

  test('download installs the font, reports progress and registers it', () async {
    await state();
    final progress = <double?>[];
    container.listen(fontLibraryProvider, (_, next) {
      final value = next.value?.downloading['Hind Vadodara'];
      if (next.value?.downloading.containsKey('Hind Vadodara') ?? false) progress.add(value);
    });

    final entry = await library().download(catalogFont);

    expect(entry.family, 'Hind Vadodara');
    expect(entry.isImported, isFalse);
    expect(registered, ['Hind Vadodara']);
    expect(progress, containsAllInOrder(<double?>[null, 0.5, 1.0]));
    final after = await state();
    expect(after.isInstalled('Hind Vadodara'), isTrue);
    expect(after.downloading, isEmpty);
  });

  test('downloads persist across app restarts and are re-registered', () async {
    await state();
    await library().download(catalogFont);
    container.dispose();
    registered.clear();

    container = makeContainer();
    final restarted = await state();

    expect(restarted.isInstalled('Hind Vadodara'), isTrue);
    expect(registered, ['Hind Vadodara']);
  });

  test('a failed download clears progress and installs nothing', () async {
    await state();
    server.online = false;

    await expectLater(library().download(catalogFont), throwsA(isA<FontDownloadException>()));

    final after = await state();
    expect(after.downloading, isEmpty);
    expect(after.fonts, isEmpty);
  });

  test('importFile installs legacy fonts under a user family named after the file', () async {
    await state();

    final entry = await library().importFile(fileName: 'Kruti Dev 010.OTF', bytes: otf);

    expect(entry.displayName, 'Kruti Dev 010');
    expect(entry.family, 'user:Kruti Dev 010');
    expect(entry.isImported, isTrue);
    expect(entry.relativePath, endsWith('.otf'));
    expect((await state()).isInstalled('user:Kruti Dev 010'), isTrue);

    // Importing the same file again reuses the existing entry.
    final again = await library().importFile(fileName: 'Kruti Dev 010.otf', bytes: otf);
    expect(again.id, entry.id);
    expect((await state()).fonts, hasLength(1));
  });

  test('importFile rejects files that are not fonts', () async {
    await state();
    await expectLater(
      library().importFile(fileName: 'photo.ttf', bytes: Uint8List.fromList(List.filled(40, 9))),
      throwsA(isA<FontImportException>()),
    );
    expect((await state()).fonts, isEmpty);
  });

  test('usageCount counts projects whose text uses the family', () async {
    ProjectModel withFont(String id, String family) => ProjectModel(
          id: id,
          title: id,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          layers: [TextLayer(id: 't', x: 0.5, y: 0.5, text: 'x', fontFamily: family)],
        );
    await projects.saveProject(withFont('a', 'Hind Vadodara'));
    await projects.saveProject(withFont('b', 'Hind Vadodara'));
    await projects.saveProject(withFont('c', 'Poppins'));

    expect(await library().usageCount('Hind Vadodara'), 2);
    expect(await library().usageCount('Anton'), 0);
  });

  test('delete uninstalls; downloading again restores the same family', () async {
    await state();
    final entry = await library().download(catalogFont);

    await library().delete(entry);
    expect((await state()).isInstalled('Hind Vadodara'), isFalse);
    expect((await fonts.resolve(entry.relativePath)).existsSync(), isFalse);

    final again = await library().download(catalogFont);
    expect(again.family, entry.family);
    expect((await state()).isInstalled('Hind Vadodara'), isTrue);
  });

  test('a font whose file went missing is skipped at startup', () async {
    final broken = await fonts.save(
      family: 'Anton',
      displayName: 'Anton',
      isImported: false,
      bytes: FakeFontServer.ttf,
      format: FontFileFormat.trueType,
    );
    await (await fonts.resolve(broken.relativePath)).delete();

    final loaded = await state();

    expect(loaded.isInstalled('Anton'), isFalse);
  });

  group('reachability and previews', () {
    test('reachability follows the server and can be retried', () async {
      container.listen(fontServerReachabilityProvider, (_, _) {});
      expect(await container.read(fontServerReachabilityProvider.future), isTrue);

      server.online = false;
      await container.read(fontServerReachabilityProvider.notifier).retry();
      expect(container.read(fontServerReachabilityProvider).value, isFalse);
    });

    test('previews installed fonts with themselves and others with a subset', () async {
      await library().download(catalogFont);
      expect(await container.read(fontPreviewFamilyProvider('Hind Vadodara').future),
          'Hind Vadodara');

      expect(await container.read(fontPreviewFamilyProvider('Anton').future), 'preview:Anton');
      expect(registered, contains('preview:Anton'));
      expect(server.requested.any((u) => u.queryParameters['text'] == 'Anton'), isTrue);
    });

    test('a preview that cannot load falls back to null', () async {
      await state();
      server.online = false;
      expect(await container.read(fontPreviewFamilyProvider('Anton').future), isNull);
    });
  });
}
