// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton [FontService].

@ProviderFor(fontService)
final fontServiceProvider = FontServiceProvider._();

/// App-wide singleton [FontService].

final class FontServiceProvider
    extends $FunctionalProvider<FontService, FontService, FontService>
    with $Provider<FontService> {
  /// App-wide singleton [FontService].
  FontServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontServiceHash();

  @$internal
  @override
  $ProviderElement<FontService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FontService create(Ref ref) {
    return fontService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FontService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FontService>(value),
    );
  }
}

String _$fontServiceHash() => r'fa4a96dc89743c9e209c651caf19de57ed53d248';
