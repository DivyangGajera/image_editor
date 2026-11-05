// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watermark_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Logo source used by the watermark settings; overridden in tests.

@ProviderFor(logoFileSource)
final logoFileSourceProvider = LogoFileSourceProvider._();

/// Logo source used by the watermark settings; overridden in tests.

final class LogoFileSourceProvider
    extends $FunctionalProvider<LogoFileSource, LogoFileSource, LogoFileSource>
    with $Provider<LogoFileSource> {
  /// Logo source used by the watermark settings; overridden in tests.
  LogoFileSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logoFileSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logoFileSourceHash();

  @$internal
  @override
  $ProviderElement<LogoFileSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LogoFileSource create(Ref ref) {
    return logoFileSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogoFileSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogoFileSource>(value),
    );
  }
}

String _$logoFileSourceHash() => r'7635fa1cd6397f635899e8edd0fce1623bf3573b';

/// Logo normalizer used by the watermark settings; overridden in tests.

@ProviderFor(logoNormalizer)
final logoNormalizerProvider = LogoNormalizerProvider._();

/// Logo normalizer used by the watermark settings; overridden in tests.

final class LogoNormalizerProvider
    extends $FunctionalProvider<LogoNormalizer, LogoNormalizer, LogoNormalizer>
    with $Provider<LogoNormalizer> {
  /// Logo normalizer used by the watermark settings; overridden in tests.
  LogoNormalizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logoNormalizerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logoNormalizerHash();

  @$internal
  @override
  $ProviderElement<LogoNormalizer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LogoNormalizer create(Ref ref) {
    return logoNormalizer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogoNormalizer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogoNormalizer>(value),
    );
  }
}

String _$logoNormalizerHash() => r'82f3423ea69b02e63d2a3393bf744c1f06acb32a';

/// The user's remembered brand watermark, set up once and offered on every
/// export.

@ProviderFor(WatermarkSettingsNotifier)
final watermarkSettingsProvider = WatermarkSettingsNotifierProvider._();

/// The user's remembered brand watermark, set up once and offered on every
/// export.
final class WatermarkSettingsNotifierProvider
    extends $AsyncNotifierProvider<WatermarkSettingsNotifier, WatermarkConfig> {
  /// The user's remembered brand watermark, set up once and offered on every
  /// export.
  WatermarkSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watermarkSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watermarkSettingsNotifierHash();

  @$internal
  @override
  WatermarkSettingsNotifier create() => WatermarkSettingsNotifier();
}

String _$watermarkSettingsNotifierHash() =>
    r'6a58a1508136a57caeb85ef79039f7a421b6c26e';

/// The user's remembered brand watermark, set up once and offered on every
/// export.

abstract class _$WatermarkSettingsNotifier
    extends $AsyncNotifier<WatermarkConfig> {
  FutureOr<WatermarkConfig> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WatermarkConfig>, WatermarkConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WatermarkConfig>, WatermarkConfig>,
              AsyncValue<WatermarkConfig>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
