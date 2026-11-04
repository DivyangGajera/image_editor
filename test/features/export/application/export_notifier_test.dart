import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/export/application/canvas_export_service.dart';
import 'package:image_editor/features/export/application/export_notifier.dart';
import 'package:image_editor/features/export/domain/models/models.dart';
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

  group('ExportState', () {
    test('default state initialization', () {
      const state = ExportState();
      expect(state.isExporting, isFalse);
      expect(state.progress, isNull);
      expect(state.exportedFilePath, isNull);
      expect(state.exportedBytes, isNull);
      expect(state.error, isNull);
    });

    test('copyWith works correctly with overrides and clear flags', () {
      const state = ExportState();
      final updated = state.copyWith(
        isExporting: true,
        progress: 0.5,
        exportedFilePath: '/exports/img.png',
        exportedBytes: Uint8List.fromList([1, 2, 3]),
        error: 'err',
      );

      expect(updated.isExporting, isTrue);
      expect(updated.progress, equals(0.5));
      expect(updated.exportedFilePath, equals('/exports/img.png'));
      expect(updated.exportedBytes, equals([1, 2, 3]));
      expect(updated.error, equals('err'));

      final cleared = updated.copyWith(
        clearExport: true,
        clearError: true,
      );

      expect(cleared.exportedFilePath, isNull);
      expect(cleared.exportedBytes, isNull);
      expect(cleared.error, isNull);
      expect(cleared.isExporting, isTrue);
    });
  });

  group('ExportNotifier', () {
    late MockCanvasExportService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockCanvasExportService();
      container = ProviderContainer(
        overrides: [
          canvasExportServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('exportProject executes render and save successfully', () async {
      final project = ProjectModel(
        id: 'p1',
        title: 'Project 1',
        canvasWidth: 500,
        canvasHeight: 500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const config = ExportConfig(format: ExportFormat.png);
      final fakeBytes = Uint8List.fromList([10, 20, 30]);

      when(() => mockService.renderCanvasToBytes(
            project: any(named: 'project'),
            config: any(named: 'config'),
          )).thenAnswer((_) async => fakeBytes);

      when(() => mockService.saveExportToGallery(
            bytes: any(named: 'bytes'),
            filename: any(named: 'filename'),
          )).thenAnswer((_) async => '/storage/Exports/p1.png');

      final result = await container
          .read(exportProvider.notifier)
          .exportProject(project: project, config: config, filename: 'p1.png');

      expect(result, equals('/storage/Exports/p1.png'));

      final state = container.read(exportProvider);
      expect(state.isExporting, isFalse);
      expect(state.exportedFilePath, equals('/storage/Exports/p1.png'));
      expect(state.exportedBytes, equals(fakeBytes));
      expect(state.error, isNull);

      verify(() => mockService.renderCanvasToBytes(
            project: project,
            config: config,
          )).called(1);

      verify(() => mockService.saveExportToGallery(
            bytes: fakeBytes,
            filename: 'p1.png',
          )).called(1);
    });

    test('exportProject updates error state when service throws', () async {
      final project = ProjectModel(
        id: 'p_err',
        title: 'Error Project',
        canvasWidth: 100,
        canvasHeight: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockService.renderCanvasToBytes(
            project: any(named: 'project'),
            config: any(named: 'config'),
          )).thenThrow(Exception('GPU render timeout'));

      expect(
        () => container.read(exportProvider.notifier).exportProject(
              project: project,
              config: const ExportConfig(),
            ),
        throwsA(isA<Exception>()),
      );

      final state = container.read(exportProvider);
      expect(state.isExporting, isFalse);
      expect(state.error, contains('GPU render timeout'));
    });

    test('clear resets state to default', () {
      final notifier = container.read(exportProvider.notifier);
      notifier.clear();
      expect(container.read(exportProvider), equals(const ExportState()));
    });
  });
}
