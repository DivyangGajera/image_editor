// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_commands.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [EditorCommands] bound to the canvas of [projectId].

@ProviderFor(editorCommands)
final editorCommandsProvider = EditorCommandsFamily._();

/// [EditorCommands] bound to the canvas of [projectId].

final class EditorCommandsProvider
    extends $FunctionalProvider<EditorCommands, EditorCommands, EditorCommands>
    with $Provider<EditorCommands> {
  /// [EditorCommands] bound to the canvas of [projectId].
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

String _$editorCommandsHash() => r'ad31f40c6d3867033892e84a782547e74005bf75';

/// [EditorCommands] bound to the canvas of [projectId].

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

  EditorCommandsProvider call(String projectId) =>
      EditorCommandsProvider._(argument: projectId, from: this);

  @override
  String toString() => r'editorCommandsProvider';
}
