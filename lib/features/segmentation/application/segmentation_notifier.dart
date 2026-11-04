import 'package:flutter/foundation.dart';
import 'package:image_editor/features/layers/domain/models/image_layer.dart';
import 'package:image_editor/features/segmentation/application/background_removal_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'segmentation_notifier.g.dart';

/// State representation for background extraction operations.
@immutable
class SegmentationState {
  const SegmentationState({
    this.isProcessing = false,
    this.progress,
    this.error,
  });

  /// Whether an extraction job is currently executing.
  final bool isProcessing;

  /// Optional fractional progress indicator between 0.0 and 1.0 (null for indeterminate).
  final double? progress;

  /// Error message if the segmentation job failed.
  final String? error;

  SegmentationState copyWith({
    bool? isProcessing,
    double? progress,
    String? error,
    bool clearError = false,
    bool clearProgress = false,
  }) {
    return SegmentationState(
      isProcessing: isProcessing ?? this.isProcessing,
      progress: clearProgress ? null : (progress ?? this.progress),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentationState &&
          runtimeType == other.runtimeType &&
          isProcessing == other.isProcessing &&
          progress == other.progress &&
          error == other.error;

  @override
  int get hashCode => Object.hash(isProcessing, progress, error);
}

/// Riverpod notifier managing state and execution of offline background extractions.
@Riverpod(keepAlive: true)
class SegmentationNotifier extends _$SegmentationNotifier {
  @override
  SegmentationState build() => const SegmentationState();

  /// Initiates an offline background extraction, updating [isProcessing] state and returning
  /// the extracted [ImageLayer].
  Future<ImageLayer?> extractBackground({
    required String sourceImagePath,
    required String projectId,
    double confidenceThreshold = 0.7,
    bool smoothEdges = true,
  }) async {
    state = const SegmentationState(isProcessing: true);

    try {
      final service = ref.read(backgroundRemovalServiceProvider);
      final layer = await service.removeBackground(
        sourceImagePath: sourceImagePath,
        projectId: projectId,
        confidenceThreshold: confidenceThreshold,
        smoothEdges: smoothEdges,
      );

      state = const SegmentationState(isProcessing: false);
      return layer;
    } catch (e) {
      state = SegmentationState(
        isProcessing: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Clears any existing error state.
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }
}
