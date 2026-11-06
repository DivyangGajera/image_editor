// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tour_registry.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide [TourRegistry].

@ProviderFor(tourRegistry)
final tourRegistryProvider = TourRegistryProvider._();

/// App-wide [TourRegistry].

final class TourRegistryProvider extends $FunctionalProvider<TourRegistry, TourRegistry, TourRegistry>
    with $Provider<TourRegistry> {
  /// App-wide [TourRegistry].
  TourRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tourRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tourRegistryHash();

  @$internal
  @override
  $ProviderElement<TourRegistry> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  TourRegistry create(Ref ref) {
    return tourRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TourRegistry value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<TourRegistry>(value));
  }
}

String _$tourRegistryHash() => r'636a5634bfba4c8317fbd7918a807616c2d7329d';
