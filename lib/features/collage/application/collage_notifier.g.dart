// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collage_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier managing collage setup, layout selection, and creation.

@ProviderFor(CollageNotifier)
final collageProvider = CollageNotifierProvider._();

/// Riverpod notifier managing collage setup, layout selection, and creation.
final class CollageNotifierProvider
    extends $NotifierProvider<CollageNotifier, CollageState> {
  /// Riverpod notifier managing collage setup, layout selection, and creation.
  CollageNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collageNotifierHash();

  @$internal
  @override
  CollageNotifier create() => CollageNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CollageState>(value),
    );
  }
}

String _$collageNotifierHash() => r'1e0ca220d86ed8c2195747d909e4ec0a4893500f';

/// Riverpod notifier managing collage setup, layout selection, and creation.

abstract class _$CollageNotifier extends $Notifier<CollageState> {
  CollageState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CollageState, CollageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CollageState, CollageState>,
              CollageState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
