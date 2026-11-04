import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/export/application/canvas_export_service.dart';
import 'package:image_editor/features/export/domain/models/models.dart';
import 'package:image_editor/features/export/presentation/widgets/export_dialog.dart';
import 'package:mocktail/mocktail.dart';

class MockCanvasExportService extends Mock implements CanvasExportService {}

class FakeProjectModel extends Fake implements ProjectModel {}

class FakeExportConfig extends Fake implements ExportConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProjectModel());
    registerFallbackValue(FakeExportConfig());
    registerFallbackValue(Uint8List(0));
  });

  group('ExportDialog', () {
    late MockCanvasExportService mockService;
    late ProjectModel testProject;

    setUp(() {
      mockService = MockCanvasExportService();
      testProject = ProjectModel(
        id: 'test_p1',
        title: 'Dialog Test',
        canvasWidth: 1000.0,
        canvasHeight: 800.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          canvasExportServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ExportDialog(project: testProject),
          ),
        ),
      );
    }

    testWidgets('renders dialog title, dimensions, and initial options', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Export Canvas'), findsOneWidget);
      expect(find.text('1000 x 800 px'), findsOneWidget);
      expect(find.text('PNG (Lossless)'), findsOneWidget);
      expect(find.text('JPEG (Compressed)'), findsOneWidget);
      expect(find.byKey(const ValueKey('confirm_export_button')), findsOneWidget);
    });

    testWidgets('switching to JPEG shows quality slider', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // JPEG slider should not be visible initially
      expect(find.byKey(const ValueKey('jpeg_quality_slider')), findsNothing);

      // Select JPEG
      await tester.tap(find.byKey(const ValueKey('format_jpeg')));
      await tester.pumpAndSettle();

      // JPEG slider should now appear
      expect(find.byKey(const ValueKey('jpeg_quality_slider')), findsOneWidget);
      expect(find.text('JPEG Quality'), findsOneWidget);
    });

    testWidgets('selecting resolution multipliers updates canvas dimensions', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap 2x Ultra HD
      await tester.tap(find.byKey(const ValueKey('res_2x')));
      await tester.pumpAndSettle();

      // Dimensions should scale 2x: 2000 x 1600 px
      expect(find.text('2000 x 1600 px'), findsOneWidget);

      // Tap 1.5x HD
      await tester.tap(find.byKey(const ValueKey('res_1_5x')));
      await tester.pumpAndSettle();

      // Dimensions: 1500 x 1200 px
      expect(find.text('1500 x 1200 px'), findsOneWidget);
    });

    testWidgets('enabling watermark reveals watermark text and position options', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const ValueKey('enable_watermark_switch'));
      await tester.ensureVisible(switchFinder);
      expect(find.byKey(const ValueKey('watermark_text_field')), findsNothing);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final textFieldFinder = find.byKey(const ValueKey('watermark_text_field'));
      expect(textFieldFinder, findsOneWidget);
      expect(find.text('Chitred'), findsOneWidget);

      // Change watermark text
      await tester.enterText(textFieldFinder, 'Brand Watermark');
      await tester.pumpAndSettle();
      expect(find.text('Brand Watermark'), findsOneWidget);
    });

    testWidgets('tapping export button triggers service and completes export', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dummyBytes = Uint8List.fromList([1, 2, 3]);
      when(() => mockService.renderCanvasToBytes(
            project: any(named: 'project'),
            config: any(named: 'config'),
          )).thenAnswer((_) async => dummyBytes);

      when(() => mockService.saveExportToGallery(
            bytes: any(named: 'bytes'),
            filename: any(named: 'filename'),
          )).thenAnswer((_) async => '/mock/Pictures/Exports/exported.png');

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final exportButton = find.byKey(const ValueKey('confirm_export_button'));
      await tester.ensureVisible(exportButton);
      await tester.tap(exportButton);

      await tester.pump(); // Start export
      await tester.pump(const Duration(milliseconds: 100)); // Complete export
      await tester.pumpAndSettle();

      verify(() => mockService.renderCanvasToBytes(
            project: testProject,
            config: any(named: 'config'),
          )).called(1);

      verify(() => mockService.saveExportToGallery(
            bytes: dummyBytes,
            filename: any(named: 'filename'),
          )).called(1);
    });
  });
}
