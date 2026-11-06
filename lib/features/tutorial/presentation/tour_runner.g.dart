// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tour_runner.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide [TourRunner].

@ProviderFor(tourRunner)
final tourRunnerProvider = TourRunnerProvider._();

/// App-wide [TourRunner].

final class TourRunnerProvider extends $FunctionalProvider<TourRunner, TourRunner, TourRunner>
    with $Provider<TourRunner> {
  /// App-wide [TourRunner].
  TourRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tourRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tourRunnerHash();

  @$internal
  @override
  $ProviderElement<TourRunner> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  TourRunner create(Ref ref) {
    return tourRunner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TourRunner value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<TourRunner>(value));
  }
}

String _$tourRunnerHash() => r'8317325cf759c7cadba1bdbf58a9fdf511c695c4';
