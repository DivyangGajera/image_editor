import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/core/theme/app_theme.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/export/export.dart';
import 'package:mocktail/mocktail.dart';

class MockCanvasExportService extends Mock implements CanvasExportService {}

class FakeGallery implements GallerySaver {
  int saves = 0;
  GallerySaveException? failWith;

  @override
  Future<void> save(Uint8List bytes, {required String name}) async {
    if (failWith != null) throw failWith!;
    saves++;
  }

  @override
  Future<void> openGallery() async {}
}

/// Watermark settings held in memory.
class MemoryWatermarkSettings extends WatermarkSettingsNotifier {
  MemoryWatermarkSettings(this.initial);
  final WatermarkConfig initial;
  WatermarkConfig? saved;

  @override
  Future<WatermarkConfig> build() async => initial;

  @override
  Future<void> save(WatermarkConfig config) async {
    saved = config;
    state = AsyncData(config.copyWith(isEnabled: false));
  }
}

class FakeProject extends Fake implements ProjectModel {}

class FakeExportConfig extends Fake implements ExportConfig {}

void main() {
  late MockCanvasExportService service;
  late FakeGallery gallery;
  late MemoryWatermarkSettings settings;
  final List<ExportConfig> rendered = [];

  final project = ProjectModel(
    id: 'p',
    title: 'Feed',
    canvasWidth: 1080.0,
    canvasHeight: 1350.0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  final png = Uint8List.fromList(img.encodePng(img.Image(width: 8, height: 10)));

  setUpAll(() {
    registerFallbackValue(FakeProject());
    registerFallbackValue(FakeExportConfig());
  });

  Future<void> openSheet(WidgetTester tester, {WatermarkConfig watermark = const WatermarkConfig()}) async {
    service = MockCanvasExportService();
    gallery = FakeGallery();
    settings = MemoryWatermarkSettings(watermark);
    rendered.clear();
    when(() => service.renderCanvasToBytes(project: any(named: 'project'), config: any(named: 'config')))
        .thenAnswer((invocation) async {
      rendered.add(invocation.namedArguments[#config] as ExportConfig);
      return png;
    });

    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          canvasExportServiceProvider.overrideWithValue(service),
          gallerySaverProvider.overrideWithValue(gallery),
          watermarkSettingsProvider.overrideWith(() => settings),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ExportSheet.show(context, project),
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

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('shows formats, quality tiers with exact sizes and the watermark summary',
      (tester) async {
    await openSheet(tester);

    expect(find.text('PNG'), findsOneWidget);
    expect(find.text('1080 × 1350 px'), findsOneWidget);
    expect(find.text('2048 × 2560 px'), findsOneWidget);
    expect(find.text('3072 × 3840 px'), findsOneWidget);
    expect(find.text('"Chitred" · Bottom right'), findsOneWidget);
  });

  testWidgets('the main Export button exports without a watermark and saves to the gallery',
      (tester) async {
    await openSheet(tester);

    await tapVisible(tester, find.byKey(const ValueKey('res_fourK')));
    await tapVisible(tester, find.byKey(const ValueKey('export_without_watermark')));

    expect(rendered.single.watermark.isEnabled, isFalse);
    expect(rendered.single.resolution, ExportResolution.fourK);
    expect(gallery.saves, 1);
    expect(find.text('Saved to Gallery'), findsOneWidget);
    expect(find.text('Find it in the Chitred album.'), findsOneWidget);
  });

  testWidgets('Export with watermark includes the remembered watermark', (tester) async {
    await openSheet(tester, watermark: const WatermarkConfig(text: 'Shree Store'));

    await tapVisible(tester, find.byKey(const ValueKey('export_with_watermark')));

    expect(rendered.single.watermark.isEnabled, isTrue);
    expect(rendered.single.watermark.text, 'Shree Store');
  });

  testWidgets('without a usable watermark the alternative offers to set one up', (tester) async {
    await openSheet(tester, watermark: const WatermarkConfig(type: WatermarkType.logo));

    expect(find.text('Set up watermark'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('export_with_watermark')));

    expect(find.text('Brand watermark'), findsWidgets);
    expect(rendered, isEmpty);
  });

  testWidgets('a gallery failure keeps the sheet open and explains it', (tester) async {
    await openSheet(tester);
    gallery.failWith = const GallerySaveException('Allow access to photos to save your design.');

    await tapVisible(tester, find.byKey(const ValueKey('export_without_watermark')));

    expect(find.text('Allow access to photos to save your design.'), findsOneWidget);
    expect(find.byKey(const ValueKey('export_without_watermark')), findsOneWidget);
  });

  testWidgets('setting up the watermark saves text and position', (tester) async {
    await openSheet(tester);

    await tapVisible(tester, find.byKey(const ValueKey('edit_watermark')));
    await tester.enterText(find.byKey(const ValueKey('watermark_text_field')), 'Shree Store');
    await tapVisible(tester, find.byKey(const ValueKey('watermark_position_tiled')));
    await tapVisible(tester, find.byKey(const ValueKey('save_watermark')));

    expect(settings.saved!.text, 'Shree Store');
    expect(settings.saved!.position, WatermarkPosition.tiled);
    expect(find.text('"Shree Store" · Tiled'), findsOneWidget);
  });
}
