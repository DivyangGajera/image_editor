// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_download_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Downloads the background-remover model on request, checking the internet
/// first. Disposed (and the progress subscription cancelled) when the
/// download dialog closes; Play services finishes a started download anyway.

@ProviderFor(ModelDownloadNotifier)
final modelDownloadProvider = ModelDownloadNotifierProvider._();

/// Downloads the background-remover model on request, checking the internet
/// first. Disposed (and the progress subscription cancelled) when the
/// download dialog closes; Play services finishes a started download anyway.
final class ModelDownloadNotifierProvider
    extends $NotifierProvider<ModelDownloadNotifier, ModelDownloadState> {
  /// Downloads the background-remover model on request, checking the internet
  /// first. Disposed (and the progress subscription cancelled) when the
  /// download dialog closes; Play services finishes a started download anyway.
  ModelDownloadNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelDownloadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelDownloadNotifierHash();

  @$internal
  @override
  ModelDownloadNotifier create() => ModelDownloadNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelDownloadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelDownloadState>(value),
    );
  }
}

String _$modelDownloadNotifierHash() =>
    r'ab5141d3b7f6fed96c28ad8d46ea96fcc3f77c08';

/// Downloads the background-remover model on request, checking the internet
/// first. Disposed (and the progress subscription cancelled) when the
/// download dialog closes; Play services finishes a started download anyway.

abstract class _$ModelDownloadNotifier extends $Notifier<ModelDownloadState> {
  ModelDownloadState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ModelDownloadState, ModelDownloadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ModelDownloadState, ModelDownloadState>,
              ModelDownloadState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
