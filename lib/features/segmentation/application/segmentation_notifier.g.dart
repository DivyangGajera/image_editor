// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'segmentation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier managing state and execution of offline background extractions.

@ProviderFor(SegmentationNotifier)
final segmentationProvider = SegmentationNotifierProvider._();

/// Riverpod notifier managing state and execution of offline background extractions.
final class SegmentationNotifierProvider
    extends $NotifierProvider<SegmentationNotifier, SegmentationState> {
  /// Riverpod notifier managing state and execution of offline background extractions.
  SegmentationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'segmentationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$segmentationNotifierHash();

  @$internal
  @override
  SegmentationNotifier create() => SegmentationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SegmentationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SegmentationState>(value),
    );
  }
}

String _$segmentationNotifierHash() =>
    r'e1a9df192a5fdd3ef685fea6c079e9ec7aaa8648';

/// Riverpod notifier managing state and execution of offline background extractions.

abstract class _$SegmentationNotifier extends $Notifier<SegmentationState> {
  SegmentationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SegmentationState, SegmentationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SegmentationState, SegmentationState>,
              SegmentationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
