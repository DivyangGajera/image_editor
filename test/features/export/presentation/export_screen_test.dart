import 'dart:typed_data';
import 'dart:ui' as ui;

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
  final List<WatermarkConfig> saves = [];

  @override
  Future<WatermarkConfig> build() async => initial;

  @override
  Future<void> save(WatermarkConfig config) async {
    saves.add(config);
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

  Future<void> openScreen(WidgetTester tester, {WatermarkConfig watermark = const WatermarkConfig()}) async {
    service = MockCanvasExportService();
    gallery = FakeGallery();
    settings = MemoryWatermarkSettings(watermark);
    rendered.clear();
    final preview = (await tester.runAsync(() => createTestImage(width: 108, height: 135)))!;
    final logo = (await tester.runAsync(() => createTestImage(width: 40, height: 20)))!;
    when(() => service.renderPreview(any(), maxEdge: any(named: 'maxEdge'))).thenAnswer((_) async => preview.clone());
    when(() => service.loadWatermarkLogo(any())).thenAnswer((_) async => logo.clone());
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
                onPressed: () => ExportScreen.show(context, project),
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

  /// Scrolls the settings list until [finder] is built and on screen.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        150.0,
        scrollable: find
            .descendant(of: find.byKey(const ValueKey('export_screen_list')), matching: find.byType(Scrollable))
            .first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  WatermarkPreviewPainter? previewPainter(WidgetTester tester) {
    final paint = find.byKey(const ValueKey('export_preview_watermark'));
    if (paint.evaluate().isEmpty) return null;
    return tester.widget<CustomPaint>(paint).painter! as WatermarkPreviewPainter;
  }

  testWidgets('shows the design preview with the watermark painted on it', (tester) async {
    await openScreen(tester);

    expect(find.byKey(const ValueKey('export_preview_image')), findsOneWidget);
    expect(previewPainter(tester)!.watermark.text, 'Chitred');
    expect(find.text('1080 × 1350 px'), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey('preview_watermark_switch')));
    expect(previewPainter(tester), isNull, reason: 'the preview can be seen without it');
  });

  testWidgets('quality tiers show their exact output size', (tester) async {
    await openScreen(tester);

    await tapVisible(tester, find.byKey(const ValueKey('res_fourK')));
    expect(find.text('3072 × 3840 px'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('res_twoK')));
    expect(find.text('2048 × 2560 px'), findsOneWidget);
  });

  testWidgets('Export saves without a watermark and closes with the success sheet', (tester) async {
    await openScreen(tester);

    await tapVisible(tester, find.byKey(const ValueKey('res_fourK')));
    await tapVisible(tester, find.byKey(const ValueKey('export_without_watermark')));

    expect(rendered.single.watermark.isEnabled, isFalse);
    expect(rendered.single.resolution, ExportResolution.fourK);
    expect(gallery.saves, 1);
    expect(find.byType(ExportScreen), findsNothing);
    expect(find.text('Saved to Gallery'), findsOneWidget);
  });

  testWidgets('edits update the live preview and are exported with the watermark', (tester) async {
    await openScreen(tester);

    await reveal(tester, find.byKey(const ValueKey('watermark_text_field')));
    await tester.enterText(find.byKey(const ValueKey('watermark_text_field')), 'Shree Store');
    // Close the keyboard, as a user would before picking a position.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('watermark_position_tiled')));
    expect(previewPainter(tester)!.watermark.text, 'Shree Store');
    expect(previewPainter(tester)!.watermark.position, WatermarkPosition.tiled);

    await tapVisible(tester, find.byKey(const ValueKey('export_with_watermark')));

    final watermark = rendered.single.watermark;
    expect(watermark.isEnabled, isTrue);
    expect(watermark.text, 'Shree Store');
    expect(watermark.position, WatermarkPosition.tiled);
    expect(settings.saves.last.text, 'Shree Store', reason: 'remembered for next time');
  });

  testWidgets('watermark changes are remembered automatically', (tester) async {
    await openScreen(tester);

    await reveal(tester, find.byKey(const ValueKey('watermark_position_center')));
    await tester.tap(find.byKey(const ValueKey('watermark_position_center')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(settings.saves, isEmpty, reason: 'saving waits for the user to pause');
    await tester.pump(const Duration(milliseconds: 500));

    expect(settings.saves.single.position, WatermarkPosition.center);
  });

  testWidgets('a logo watermark previews the logo and its size follows the slider', (tester) async {
    await openScreen(
      tester,
      watermark: const WatermarkConfig(type: WatermarkType.logo, logoRelativePath: 'branding/logo.png'),
    );

    final before = previewPainter(tester)!;
    expect(before.logo, isNotNull);
    expect(before.watermark.logoScale, WatermarkConfig.defaultLogoScale);

    final slider = find.byKey(const ValueKey('logo_size_slider'));
    await reveal(tester, slider);
    await tester.drag(slider, const Offset(200.0, 0.0));
    await tester.pumpAndSettle();

    expect(previewPainter(tester)!.watermark.logoScale, greaterThan(WatermarkConfig.defaultLogoScale));
    await tapVisible(tester, find.byKey(const ValueKey('export_with_watermark')));
    expect(rendered.single.watermark.logoScale, greaterThan(WatermarkConfig.defaultLogoScale));
  });

  testWidgets('without a logo, Export with watermark is disabled and explained', (tester) async {
    await openScreen(tester, watermark: const WatermarkConfig(type: WatermarkType.logo));

    final button = tester.widget<ButtonStyleButton>(find.byKey(const ValueKey('export_with_watermark')));
    expect(button.onPressed, isNull);
    expect(find.text('Choose a logo to export with a watermark.'), findsOneWidget);
  });

  testWidgets('a gallery failure keeps the screen open and explains it', (tester) async {
    await openScreen(tester);
    gallery.failWith = const GallerySaveException('Allow access to photos to save your design.');

    await tapVisible(tester, find.byKey(const ValueKey('export_without_watermark')));

    expect(find.text('Allow access to photos to save your design.'), findsOneWidget);
    expect(find.byType(ExportScreen), findsOneWidget);
  });

  test('the preview painter draws in canvas units scaled to the preview', () {
    final recorder = ui.PictureRecorder();
    const painter = WatermarkPreviewPainter(
      canvasSize: Size(1080, 1350),
      watermark: WatermarkConfig(text: 'Shop'),
    );
    painter.paint(Canvas(recorder), const Size(108, 135));
    recorder.endRecording().dispose();

    expect(
      painter.shouldRepaint(const WatermarkPreviewPainter(
        canvasSize: Size(1080, 1350),
        watermark: WatermarkConfig(text: 'Shop 2'),
      )),
      isTrue,
    );
  });
}
