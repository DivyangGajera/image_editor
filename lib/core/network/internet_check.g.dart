// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'internet_check.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide [InternetCheck]; overridden in tests.

@ProviderFor(internetCheck)
final internetCheckProvider = InternetCheckProvider._();

/// App-wide [InternetCheck]; overridden in tests.

final class InternetCheckProvider
    extends $FunctionalProvider<InternetCheck, InternetCheck, InternetCheck>
    with $Provider<InternetCheck> {
  /// App-wide [InternetCheck]; overridden in tests.
  InternetCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'internetCheckProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$internetCheckHash();

  @$internal
  @override
  $ProviderElement<InternetCheck> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InternetCheck create(Ref ref) {
    return internetCheck(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InternetCheck value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InternetCheck>(value),
    );
  }
}

String _$internetCheckHash() => r'd924a60b6300681f7d9a30b04ce99502fe023d22';
