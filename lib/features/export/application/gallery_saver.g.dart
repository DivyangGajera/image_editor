// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_saver.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide [GallerySaver]; overridden in tests.

@ProviderFor(gallerySaver)
final gallerySaverProvider = GallerySaverProvider._();

/// App-wide [GallerySaver]; overridden in tests.

final class GallerySaverProvider
    extends $FunctionalProvider<GallerySaver, GallerySaver, GallerySaver>
    with $Provider<GallerySaver> {
  /// App-wide [GallerySaver]; overridden in tests.
  GallerySaverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gallerySaverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gallerySaverHash();

  @$internal
  @override
  $ProviderElement<GallerySaver> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GallerySaver create(Ref ref) {
    return gallerySaver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GallerySaver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GallerySaver>(value),
    );
  }
}

String _$gallerySaverHash() => r'6d264bc12344675b9bd477fa6ef47bf66c4bffcb';
