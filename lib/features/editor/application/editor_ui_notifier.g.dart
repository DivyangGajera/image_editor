// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_ui_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Editor UI state for one open project; reset when the editor closes.

@ProviderFor(EditorUiNotifier)
final editorUiProvider = EditorUiNotifierFamily._();

/// Editor UI state for one open project; reset when the editor closes.
final class EditorUiNotifierProvider
    extends $NotifierProvider<EditorUiNotifier, EditorUiState> {
  /// Editor UI state for one open project; reset when the editor closes.
  EditorUiNotifierProvider._({
    required EditorUiNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'editorUiProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$editorUiNotifierHash();

  @override
  String toString() {
    return r'editorUiProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EditorUiNotifier create() => EditorUiNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditorUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditorUiState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EditorUiNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$editorUiNotifierHash() => r'eacc0df7c6a3fd7f45b5c1a282354935026d3725';

/// Editor UI state for one open project; reset when the editor closes.

final class EditorUiNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          EditorUiNotifier,
          EditorUiState,
          EditorUiState,
          EditorUiState,
          String
        > {
  EditorUiNotifierFamily._()
    : super(
        retry: null,
        name: r'editorUiProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Editor UI state for one open project; reset when the editor closes.

  EditorUiNotifierProvider call(String projectId) =>
      EditorUiNotifierProvider._(argument: projectId, from: this);

  @override
  String toString() => r'editorUiProvider';
}

/// Editor UI state for one open project; reset when the editor closes.

abstract class _$EditorUiNotifier extends $Notifier<EditorUiState> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  EditorUiState build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EditorUiState, EditorUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EditorUiState, EditorUiState>,
              EditorUiState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
