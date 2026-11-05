// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_removal_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton [BackgroundRemovalService].

@ProviderFor(backgroundRemovalService)
final backgroundRemovalServiceProvider = BackgroundRemovalServiceProvider._();

/// App-wide singleton [BackgroundRemovalService].

final class BackgroundRemovalServiceProvider
    extends
        $FunctionalProvider<
          BackgroundRemovalService,
          BackgroundRemovalService,
          BackgroundRemovalService
        >
    with $Provider<BackgroundRemovalService> {
  /// App-wide singleton [BackgroundRemovalService].
  BackgroundRemovalServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundRemovalServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundRemovalServiceHash();

  @$internal
  @override
  $ProviderElement<BackgroundRemovalService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundRemovalService create(Ref ref) {
    return backgroundRemovalService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundRemovalService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundRemovalService>(value),
    );
  }
}

String _$backgroundRemovalServiceHash() =>
    r'd3586dc436928d811793819422c52310a120d864';
