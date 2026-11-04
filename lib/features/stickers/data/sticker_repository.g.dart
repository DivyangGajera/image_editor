// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sticker_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton [StickerRepository].

@ProviderFor(stickerRepository)
final stickerRepositoryProvider = StickerRepositoryProvider._();

/// App-wide singleton [StickerRepository].

final class StickerRepositoryProvider
    extends
        $FunctionalProvider<
          StickerRepository,
          StickerRepository,
          StickerRepository
        >
    with $Provider<StickerRepository> {
  /// App-wide singleton [StickerRepository].
  StickerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stickerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stickerRepositoryHash();

  @$internal
  @override
  $ProviderElement<StickerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StickerRepository create(Ref ref) {
    return stickerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StickerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StickerRepository>(value),
    );
  }
}

String _$stickerRepositoryHash() => r'296e8706eebcca2c3aecb2283dd581e1ca60d134';
