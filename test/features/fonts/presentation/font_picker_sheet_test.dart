import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/app_bootstrap.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/canvas/canvas.dart';
import 'package:image_editor/features/fonts/fonts.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

class FakeFontServer implements HttpGetter {
  bool online = true;
  static final Uint8List ttf =
      Uint8List.fromList([0x00, 0x01, 0x00, 0x00, ...List<int>.filled(96, 3)]);

  @override
  Future<HttpGetResponse> get(
    Uri url, {
    Map<String, String> headers = const {},
    required Duration timeout,
    ProgressCallback? onProgress,
  }) async {
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
    return HttpGetResponse(200, ttf);
  }
}

class FakeFilePicker extends FontFilePicker {
  FakeFilePicker(this.result);
  PickedFontFile? result;

  @override
  Future<PickedFontFile?> pick() async => result;
}

void main() {
  late Directory tempDir;
  late FontRepository fonts;
  late ProjectRepository projects;
  late FakeFontServer server;
  late FakeFilePicker filePicker;
  late ProviderContainer container;
  String? picked;

  final otf = Uint8List.fromList([...'OTTO'.codeUnits, ...List<int>.filled(60, 1)]);

  setUpAll(AppBootstrap.registerAdapters);

  Future<void> setUpStorage() async {
    tempDir = await Directory.systemTemp.createTemp('font_picker_test_');
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
    filePicker = FakeFilePicker(null);
    container = ProviderContainer(
      overrides: [
        fontRepositoryProvider.overrideWithValue(fonts),
        projectRepositoryProvider.overrideWithValue(projects),
        googleFontsClientProvider.overrideWithValue(GoogleFontsClient(http: server)),
        fontRegistrarProvider.overrideWithValue((bytes, family) async {}),
        fontFilePickerProvider.overrideWithValue(filePicker),
      ],
    );
    await container.read(fontLibraryProvider.future);
  }

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<void> openPicker(WidgetTester tester, {String current = systemDefaultFontFamily}) async {
    picked = null;
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
                onPressed: () async =>
                    picked = await FontPickerSheet.show(context, currentFamily: current),
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

  /// Runs [action] with real async I/O, then lets the UI settle.
  Future<void> real(WidgetTester tester, Future<void> Function() action) async {
    await tester.runAsync(() async {
      await action();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  Future<void> tapReal(WidgetTester tester, Finder finder) =>
      real(tester, () async => tester.tap(finder));

  /// Pumps frames (letting real I/O run) until [condition] holds, without
  /// pumpAndSettle: a download spinner animates until the download ends.
  Future<void> pumpUntil(WidgetTester tester, bool Function() condition) async {
    for (var i = 0; i < 200 && !condition(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(condition(), isTrue, reason: 'condition not reached in time');
    await tester.pumpAndSettle();
  }

  bool installed(String family) =>
      container.read(fontLibraryProvider).value?.isInstalled(family) ?? false;

  Future<void> openDownloadTab(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('tab_download')));
    // The reachability check runs real (fake-server) futures.
    await real(tester, () async {});
  }

  testWidgets('my fonts lists the default font; choosing it returns its family', (tester) async {
    await tester.runAsync(setUpStorage);
    await openPicker(tester, current: 'Poppins');

    expect(find.byKey(const ValueKey('font_row_default')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('font_row_default')));
    await tester.pumpAndSettle();

    expect(picked, systemDefaultFontFamily);
  });

  testWidgets('download tab shows an offline state and recovers on retry', (tester) async {
    await tester.runAsync(setUpStorage);
    server.online = false;
    await openPicker(tester);
    await openDownloadTab(tester);

    expect(find.text('No internet connection'), findsOneWidget);

    server.online = true;
    await tapReal(tester, find.byKey(const ValueKey('retry_connection')));

    expect(find.byKey(const ValueKey('offline_view')), findsNothing);
    expect(find.byKey(const ValueKey('font_search')), findsOneWidget);
  });

  testWidgets('script filter and search narrow the catalog', (tester) async {
    await tester.runAsync(setUpStorage);
    await openPicker(tester);
    await openDownloadTab(tester);

    await tester.tap(find.byKey(const ValueKey('script_gujarati')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('catalog_row_Hind Vadodara')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog_row_Poppins')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('script_all')));
    await tester.enterText(find.byKey(const ValueKey('font_search')), 'bebas');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('catalog_row_Bebas Neue')), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('download installs a font and shows it as installed', (tester) async {
    await tester.runAsync(setUpStorage);
    await openPicker(tester);
    await openDownloadTab(tester);
    await tester.tap(find.byKey(const ValueKey('script_gujarati')));
    await tester.pumpAndSettle();

    // Tap in the real zone so the download's file and Hive writes can finish.
    await tester.runAsync(
      () async => tester.tap(find.byKey(const ValueKey('download_Hind Vadodara'))),
    );
    await pumpUntil(tester, () => installed('Hind Vadodara'));

    expect(find.byKey(const ValueKey('download_Hind Vadodara')), findsNothing);
    expect(find.text('Sans · Gujarati · Installed'), findsOneWidget);
  });

  testWidgets('importing a non-font file shows a clear message', (tester) async {
    await tester.runAsync(setUpStorage);
    await openPicker(tester);

    filePicker.result = PickedFontFile(name: 'notes.ttf', bytes: Uint8List.fromList([1, 2, 3]));
    await tapReal(tester, find.byKey(const ValueKey('import_font_button')));

    expect(find.text('This file is not a TTF or OTF font.'), findsOneWidget);
    expect(container.read(fontLibraryProvider).value!.fonts, isEmpty);
    // Let the snackbar finish before the tree is torn down.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('importing a legacy font adds it to my fonts', (tester) async {
    await tester.runAsync(setUpStorage);
    await openPicker(tester);

    filePicker.result = PickedFontFile(name: 'Kruti Dev 010.otf', bytes: otf);
    await tapReal(tester, find.byKey(const ValueKey('import_font_button')));

    expect(find.byKey(const ValueKey('font_row_user:Kruti Dev 010')), findsOneWidget);
    expect(find.text('Imported · 64 B'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('deleting a font in use warns how many projects use it', (tester) async {
    await tester.runAsync(() async {
      await setUpStorage();
      await container
          .read(fontLibraryProvider.notifier)
          .download(const CatalogFont('Anton', FontCategory.display, FontScript.latin));
      await projects.saveProject(ProjectModel(
        id: 'p',
        title: 'Sale',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        layers: const [TextLayer(id: 't', x: 0.5, y: 0.5, text: 'x', fontFamily: 'Anton')],
      ));
    });
    await openPicker(tester);

    await tapReal(tester, find.byKey(const ValueKey('delete_font_Anton')));
    expect(find.textContaining('Used in 1 project'), findsOneWidget);

    await tapReal(tester, find.byKey(const ValueKey('confirm_delete_font')));
    expect(container.read(fontLibraryProvider).value!.isInstalled('Anton'), isFalse);
  });

  testWidgets('a missing current font shows a banner with one-tap re-download', (tester) async {
    await tester.runAsync(setUpStorage);
    await openPicker(tester, current: 'Anton');

    expect(find.byKey(const ValueKey('missing_font_banner')), findsOneWidget);
    await tester.runAsync(
      () async => tester.tap(find.byKey(const ValueKey('redownload_missing_font'))),
    );
    await pumpUntil(tester, () => installed('Anton'));

    expect(find.byKey(const ValueKey('missing_font_banner')), findsNothing);
  });

  test('formatFontSize uses B, KB and MB', () {
    expect(formatFontSize(512), '512 B');
    expect(formatFontSize(128 * 1024), '128 KB');
    expect(formatFontSize(3 * 1024 * 1024 + 100000), '3.1 MB');
  });
}
