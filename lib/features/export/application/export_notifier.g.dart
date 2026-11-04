// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier coordinating headless export jobs and local gallery persistence.

@ProviderFor(ExportNotifier)
final exportProvider = ExportNotifierProvider._();

/// Riverpod notifier coordinating headless export jobs and local gallery persistence.
final class ExportNotifierProvider
    extends $NotifierProvider<ExportNotifier, ExportState> {
  /// Riverpod notifier coordinating headless export jobs and local gallery persistence.
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

String _$exportNotifierHash() => r'20d5875df9e1e51beb7f6d81200b527abbea5cd3';

/// Riverpod notifier coordinating headless export jobs and local gallery persistence.

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
