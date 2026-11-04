// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_import_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton [ImageImportService].

@ProviderFor(imageImportService)
final imageImportServiceProvider = ImageImportServiceProvider._();

/// App-wide singleton [ImageImportService].

final class ImageImportServiceProvider
    extends
        $FunctionalProvider<
          ImageImportService,
          ImageImportService,
          ImageImportService
        >
    with $Provider<ImageImportService> {
  /// App-wide singleton [ImageImportService].
  ImageImportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageImportServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageImportServiceHash();

  @$internal
  @override
  $ProviderElement<ImageImportService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImageImportService create(Ref ref) {
    return imageImportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageImportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageImportService>(value),
    );
  }
}

String _$imageImportServiceHash() =>
    r'348c551a04477eb21b2156a72174d3e6ad4b8857';
