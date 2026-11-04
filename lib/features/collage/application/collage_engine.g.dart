// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collage_engine.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton [CollageEngine].

@ProviderFor(collageEngine)
final collageEngineProvider = CollageEngineProvider._();

/// App-wide singleton [CollageEngine].

final class CollageEngineProvider
    extends $FunctionalProvider<CollageEngine, CollageEngine, CollageEngine>
    with $Provider<CollageEngine> {
  /// App-wide singleton [CollageEngine].
  CollageEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collageEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collageEngineHash();

  @$internal
  @override
  $ProviderElement<CollageEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CollageEngine create(Ref ref) {
    return collageEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollageEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CollageEngine>(value),
    );
  }
}

String _$collageEngineHash() => r'faa99b91d4d5959804c7dd227e7fbeabe82448cc';
