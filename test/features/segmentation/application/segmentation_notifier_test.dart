import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/layers/domain/models/image_layer.dart';
import 'package:image_editor/features/segmentation/application/background_removal_service.dart';
import 'package:image_editor/features/segmentation/application/segmentation_notifier.dart';
import 'package:mocktail/mocktail.dart';

class MockBackgroundRemovalService extends Mock
    implements BackgroundRemovalService {}

void main() {
  group('SegmentationState', () {
    test('supports value equality and copyWith', () {
      const state1 = SegmentationState(
        isProcessing: true,
        progress: 0.5,
        error: null,
      );
      const state2 = SegmentationState(
        isProcessing: true,
        progress: 0.5,
        error: null,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));

      final updated = state1.copyWith(
        isProcessing: false,
        clearProgress: true,
        error: 'An error occurred',
      );

      expect(updated.isProcessing, isFalse);
      expect(updated.progress, isNull);
      expect(updated.error, equals('An error occurred'));

      final clearedError = updated.copyWith(clearError: true);
      expect(clearedError.error, isNull);
    });
  });

  group('SegmentationNotifier', () {
    late MockBackgroundRemovalService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockBackgroundRemovalService();
      container = ProviderContainer(
        overrides: [
          backgroundRemovalServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has isProcessing false, progress null, error null', () {
      final state = container.read(segmentationNotifierProvider);
      expect(state.isProcessing, isFalse);
      expect(state.progress, isNull);
      expect(state.error, isNull);
    });

    test('extractBackground updates state and returns cutout layer', () async {
      const expectedLayer = ImageLayer(
        id: 'layer_1',
        x: 0.5,
        y: 0.5,
        relativeImagePath: 'projects/p1/images/cutout.png',
      );

      when(
        () => mockService.removeBackground(
          sourceImagePath: any(named: 'sourceImagePath'),
          projectId: any(named: 'projectId'),
          confidenceThreshold: any(named: 'confidenceThreshold'),
          smoothEdges: any(named: 'smoothEdges'),
        ),
      ).thenAnswer((_) async => expectedLayer);

      final notifier = container.read(segmentationNotifierProvider.notifier);

      final result = await notifier.extractBackground(
        sourceImagePath: '/path/to/img.png',
        projectId: 'p1',
      );

      expect(result, equals(expectedLayer));
      expect(container.read(segmentationNotifierProvider).isProcessing, isFalse);
      expect(container.read(segmentationNotifierProvider).error, isNull);
    });

    test('sets error and rethrows when service fails', () async {
      when(
        () => mockService.removeBackground(
          sourceImagePath: any(named: 'sourceImagePath'),
          projectId: any(named: 'projectId'),
          confidenceThreshold: any(named: 'confidenceThreshold'),
          smoothEdges: any(named: 'smoothEdges'),
        ),
      ).thenThrow(Exception('ML Kit model execution failed'));

      final notifier = container.read(segmentationNotifierProvider.notifier);

      await expectLater(
        notifier.extractBackground(
          sourceImagePath: '/path/to/img.png',
          projectId: 'p1',
        ),
        throwsA(isA<Exception>()),
      );

      final errorState = container.read(segmentationNotifierProvider);
      expect(errorState.isProcessing, isFalse);
      expect(errorState.error, contains('ML Kit model execution failed'));

      notifier.clearError();
      expect(container.read(segmentationNotifierProvider).error, isNull);
    });
  });
}
