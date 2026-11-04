// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton [FontRepository].

@ProviderFor(fontRepository)
final fontRepositoryProvider = FontRepositoryProvider._();

/// App-wide singleton [FontRepository].

final class FontRepositoryProvider
    extends $FunctionalProvider<FontRepository, FontRepository, FontRepository>
    with $Provider<FontRepository> {
  /// App-wide singleton [FontRepository].
  FontRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontRepositoryHash();

  @$internal
  @override
  $ProviderElement<FontRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FontRepository create(Ref ref) {
    return fontRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FontRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FontRepository>(value),
    );
  }
}

String _$fontRepositoryHash() => r'f2a27369177207a95ac4df93cee33e537041f61e';
