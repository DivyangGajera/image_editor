// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_sticker_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton [UserStickerRepository].

@ProviderFor(userStickerRepository)
final userStickerRepositoryProvider = UserStickerRepositoryProvider._();

/// App-wide singleton [UserStickerRepository].

final class UserStickerRepositoryProvider
    extends
        $FunctionalProvider<
          UserStickerRepository,
          UserStickerRepository,
          UserStickerRepository
        >
    with $Provider<UserStickerRepository> {
  /// App-wide singleton [UserStickerRepository].
  UserStickerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStickerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStickerRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserStickerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserStickerRepository create(Ref ref) {
    return userStickerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserStickerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserStickerRepository>(value),
    );
  }
}

String _$userStickerRepositoryHash() =>
    r'fc301867623cdcbeb54e025ff58791748df4f486';
