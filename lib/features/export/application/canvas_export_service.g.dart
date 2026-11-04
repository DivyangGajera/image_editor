// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_export_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton [CanvasExportService].

@ProviderFor(canvasExportService)
final canvasExportServiceProvider = CanvasExportServiceProvider._();

/// App-wide singleton [CanvasExportService].

final class CanvasExportServiceProvider
    extends
        $FunctionalProvider<
          CanvasExportService,
          CanvasExportService,
          CanvasExportService
        >
    with $Provider<CanvasExportService> {
  /// App-wide singleton [CanvasExportService].
  CanvasExportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canvasExportServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canvasExportServiceHash();

  @$internal
  @override
  $ProviderElement<CanvasExportService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CanvasExportService create(Ref ref) {
    return canvasExportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CanvasExportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CanvasExportService>(value),
    );
  }
}

String _$canvasExportServiceHash() =>
    r'b1346f3e79d29419bb42dff5440d10c873f6f198';
