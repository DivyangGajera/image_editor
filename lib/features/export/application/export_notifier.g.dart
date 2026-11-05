// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Renders a project and saves it to the gallery's app album.

@ProviderFor(ExportNotifier)
final exportProvider = ExportNotifierProvider._();

/// Renders a project and saves it to the gallery's app album.
final class ExportNotifierProvider
    extends $NotifierProvider<ExportNotifier, ExportState> {
  /// Renders a project and saves it to the gallery's app album.
  ExportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportNotifierHash();

  @$internal
  @override
  ExportNotifier create() => ExportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportState>(value),
    );
  }
}

String _$exportNotifierHash() => r'e34f1a4f8b40d0a1007e47306928135bf595b53b';

/// Renders a project and saves it to the gallery's app album.

abstract class _$ExportNotifier extends $Notifier<ExportState> {
  ExportState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ExportState, ExportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExportState, ExportState>,
              ExportState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
