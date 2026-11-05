// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watermark_settings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton [WatermarkSettingsRepository].

@ProviderFor(watermarkSettingsRepository)
final watermarkSettingsRepositoryProvider =
    WatermarkSettingsRepositoryProvider._();

/// App-wide singleton [WatermarkSettingsRepository].

final class WatermarkSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          WatermarkSettingsRepository,
          WatermarkSettingsRepository,
          WatermarkSettingsRepository
        >
    with $Provider<WatermarkSettingsRepository> {
  /// App-wide singleton [WatermarkSettingsRepository].
  WatermarkSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watermarkSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watermarkSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<WatermarkSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatermarkSettingsRepository create(Ref ref) {
    return watermarkSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatermarkSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatermarkSettingsRepository>(value),
    );
  }
}

String _$watermarkSettingsRepositoryHash() =>
    r'5e77e15159e87c241b9e949d2226df8ec175cb0e';
