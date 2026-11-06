// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutorial_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide [TutorialRepository]; overridden in tests.

@ProviderFor(tutorialRepository)
final tutorialRepositoryProvider = TutorialRepositoryProvider._();

/// App-wide [TutorialRepository]; overridden in tests.

final class TutorialRepositoryProvider
    extends $FunctionalProvider<TutorialRepository, TutorialRepository, TutorialRepository>
    with $Provider<TutorialRepository> {
  /// App-wide [TutorialRepository]; overridden in tests.
  TutorialRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tutorialRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tutorialRepositoryHash();

  @$internal
  @override
  $ProviderElement<TutorialRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  TutorialRepository create(Ref ref) {
    return tutorialRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TutorialRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<TutorialRepository>(value));
  }
}

String _$tutorialRepositoryHash() => r'3328dcb34e8cccb959732ee978e7a0ff0db82f2c';
