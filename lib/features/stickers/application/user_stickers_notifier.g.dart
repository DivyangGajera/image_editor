// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stickers_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// File source used for sticker import; overridden in tests.

@ProviderFor(stickerFileSource)
final stickerFileSourceProvider = StickerFileSourceProvider._();

/// File source used for sticker import; overridden in tests.

final class StickerFileSourceProvider
    extends
        $FunctionalProvider<
          StickerFileSource,
          StickerFileSource,
          StickerFileSource
        >
    with $Provider<StickerFileSource> {
  /// File source used for sticker import; overridden in tests.
  StickerFileSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stickerFileSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stickerFileSourceHash();

  @$internal
  @override
  $ProviderElement<StickerFileSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StickerFileSource create(Ref ref) {
    return stickerFileSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StickerFileSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StickerFileSource>(value),
    );
  }
}

String _$stickerFileSourceHash() => r'c7327a5f96a577c51e947aa985d7c2ff8344f76c';

/// Normalizer used for sticker import; overridden in tests.

@ProviderFor(stickerNormalizer)
final stickerNormalizerProvider = StickerNormalizerProvider._();

/// Normalizer used for sticker import; overridden in tests.

final class StickerNormalizerProvider
    extends
        $FunctionalProvider<
          StickerNormalizer,
          StickerNormalizer,
          StickerNormalizer
        >
    with $Provider<StickerNormalizer> {
  /// Normalizer used for sticker import; overridden in tests.
  StickerNormalizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stickerNormalizerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stickerNormalizerHash();

  @$internal
  @override
  $ProviderElement<StickerNormalizer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StickerNormalizer create(Ref ref) {
    return stickerNormalizer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StickerNormalizer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StickerNormalizer>(value),
    );
  }
}

String _$stickerNormalizerHash() => r'31701fa850d7fc6e96aad66502715ace3b008a68';

/// The user's app-wide "My stickers" library, newest first.

@ProviderFor(UserStickersNotifier)
final userStickersProvider = UserStickersNotifierProvider._();

/// The user's app-wide "My stickers" library, newest first.
final class UserStickersNotifierProvider
    extends $AsyncNotifierProvider<UserStickersNotifier, List<UserSticker>> {
  /// The user's app-wide "My stickers" library, newest first.
  UserStickersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStickersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStickersNotifierHash();

  @$internal
  @override
  UserStickersNotifier create() => UserStickersNotifier();
}

String _$userStickersNotifierHash() =>
    r'28eda820a39f4419eba501dca8ae1d50e2ecb618';

/// The user's app-wide "My stickers" library, newest first.

abstract class _$UserStickersNotifier
    extends $AsyncNotifier<List<UserSticker>> {
  FutureOr<List<UserSticker>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<UserSticker>>, List<UserSticker>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UserSticker>>, List<UserSticker>>,
              AsyncValue<List<UserSticker>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
