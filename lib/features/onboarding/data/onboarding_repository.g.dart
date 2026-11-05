// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide [OnboardingRepository]; overridden in tests.

@ProviderFor(onboardingRepository)
final onboardingRepositoryProvider = OnboardingRepositoryProvider._();

/// App-wide [OnboardingRepository]; overridden in tests.

final class OnboardingRepositoryProvider
    extends $FunctionalProvider<OnboardingRepository, OnboardingRepository, OnboardingRepository>
    with $Provider<OnboardingRepository> {
  /// App-wide [OnboardingRepository]; overridden in tests.
  OnboardingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingRepositoryHash();

  @$internal
  @override
  $ProviderElement<OnboardingRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  OnboardingRepository create(Ref ref) {
    return onboardingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<OnboardingRepository>(value));
  }
}

String _$onboardingRepositoryHash() => r'4393aea84347e889df7d81a9965b270d48255136';
