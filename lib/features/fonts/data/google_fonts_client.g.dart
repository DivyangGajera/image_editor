// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_fonts_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton [GoogleFontsClient].

@ProviderFor(googleFontsClient)
final googleFontsClientProvider = GoogleFontsClientProvider._();

/// App-wide singleton [GoogleFontsClient].

final class GoogleFontsClientProvider
    extends
        $FunctionalProvider<
          GoogleFontsClient,
          GoogleFontsClient,
          GoogleFontsClient
        >
    with $Provider<GoogleFontsClient> {
  /// App-wide singleton [GoogleFontsClient].
  GoogleFontsClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleFontsClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleFontsClientHash();

  @$internal
  @override
  $ProviderElement<GoogleFontsClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GoogleFontsClient create(Ref ref) {
    return googleFontsClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoogleFontsClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoogleFontsClient>(value),
    );
  }
}

String _$googleFontsClientHash() => r'11bccd2d0c4de0bbeb2b2af4b3b3956bb0e0f3f7';
