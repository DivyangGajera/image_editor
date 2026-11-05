// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_commands.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [EditorCommands] bound to the canvas of [projectId].
///
/// Widgets read this provider without listening, so it is disposed right
/// after the read while a command may still be waiting for the photo picker,
/// cropper or an asset. The commands therefore hold the notifier *instances*
/// (resolved here, up front) and never use this provider's `ref` later.

@ProviderFor(editorCommands)
final editorCommandsProvider = EditorCommandsFamily._();

/// [EditorCommands] bound to the canvas of [projectId].
///
/// Widgets read this provider without listening, so it is disposed right
/// after the read while a command may still be waiting for the photo picker,
/// cropper or an asset. The commands therefore hold the notifier *instances*
/// (resolved here, up front) and never use this provider's `ref` later.

final class EditorCommandsProvider
    extends $FunctionalProvider<EditorCommands, EditorCommands, EditorCommands>
    with $Provider<EditorCommands> {
  /// [EditorCommands] bound to the canvas of [projectId].
  ///
  /// Widgets read this provider without listening, so it is disposed right
  /// after the read while a command may still be waiting for the photo picker,
  /// cropper or an asset. The commands therefore hold the notifier *instances*
  /// (resolved here, up front) and never use this provider's `ref` later.
  EditorCommandsProvider._({
    required EditorCommandsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'editorCommandsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$editorCommandsHash();

  @override
  String toString() {
    return r'editorCommandsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<EditorCommands> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EditorCommands create(Ref ref) {
    final argument = this.argument as String;
    return editorCommands(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditorCommands value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditorCommands>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EditorCommandsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$editorCommandsHash() => r'ad0be4d12a498eba93cef1a71ac30e5dcf7c1ff2';

/// [EditorCommands] bound to the canvas of [projectId].
///
/// Widgets read this provider without listening, so it is disposed right
/// after the read while a command may still be waiting for the photo picker,
/// cropper or an asset. The commands therefore hold the notifier *instances*
/// (resolved here, up front) and never use this provider's `ref` later.

final class EditorCommandsFamily extends $Family
    with $FunctionalFamilyOverride<EditorCommands, String> {
  EditorCommandsFamily._()
    : super(
        retry: null,
        name: r'editorCommandsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [EditorCommands] bound to the canvas of [projectId].
  ///
  /// Widgets read this provider without listening, so it is disposed right
  /// after the read while a command may still be waiting for the photo picker,
  /// cropper or an asset. The commands therefore hold the notifier *instances*
  /// (resolved here, up front) and never use this provider's `ref` later.

  EditorCommandsProvider call(String projectId) =>
      EditorCommandsProvider._(argument: projectId, from: this);

  @override
  String toString() => r'editorCommandsProvider';
}
