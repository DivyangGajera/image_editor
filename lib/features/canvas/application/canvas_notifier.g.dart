// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier coordinating canvas workspace layer interactions, mutations,
/// and automated history snapshot recording for a single project.
///
/// Keyed by project ID. The project is loaded from [ProjectRepository] on first
/// use; every mutation records undo history and persists the project.

@ProviderFor(CanvasNotifier)
final canvasProvider = CanvasNotifierFamily._();

/// Riverpod notifier coordinating canvas workspace layer interactions, mutations,
/// and automated history snapshot recording for a single project.
///
/// Keyed by project ID. The project is loaded from [ProjectRepository] on first
/// use; every mutation records undo history and persists the project.
final class CanvasNotifierProvider
    extends $AsyncNotifierProvider<CanvasNotifier, CanvasState> {
  /// Riverpod notifier coordinating canvas workspace layer interactions, mutations,
  /// and automated history snapshot recording for a single project.
  ///
  /// Keyed by project ID. The project is loaded from [ProjectRepository] on first
  /// use; every mutation records undo history and persists the project.
  CanvasNotifierProvider._({
    required CanvasNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'canvasProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$canvasNotifierHash();

  @override
  String toString() {
    return r'canvasProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CanvasNotifier create() => CanvasNotifier();

  @override
  bool operator ==(Object other) {
    return other is CanvasNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$canvasNotifierHash() => r'512e7df6fe9aa97edeb1ed60ddbd2490e5734532';

/// Riverpod notifier coordinating canvas workspace layer interactions, mutations,
/// and automated history snapshot recording for a single project.
///
/// Keyed by project ID. The project is loaded from [ProjectRepository] on first
/// use; every mutation records undo history and persists the project.

final class CanvasNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CanvasNotifier,
          AsyncValue<CanvasState>,
          CanvasState,
          FutureOr<CanvasState>,
          String
        > {
  CanvasNotifierFamily._()
    : super(
        retry: null,
        name: r'canvasProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Riverpod notifier coordinating canvas workspace layer interactions, mutations,
  /// and automated history snapshot recording for a single project.
  ///
  /// Keyed by project ID. The project is loaded from [ProjectRepository] on first
  /// use; every mutation records undo history and persists the project.

  CanvasNotifierProvider call(String projectId) =>
      CanvasNotifierProvider._(argument: projectId, from: this);

  @override
  String toString() => r'canvasProvider';
}

/// Riverpod notifier coordinating canvas workspace layer interactions, mutations,
/// and automated history snapshot recording for a single project.
///
/// Keyed by project ID. The project is loaded from [ProjectRepository] on first
/// use; every mutation records undo history and persists the project.

abstract class _$CanvasNotifier extends $AsyncNotifier<CanvasState> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  FutureOr<CanvasState> build(String projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CanvasState>, CanvasState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CanvasState>, CanvasState>,
              AsyncValue<CanvasState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
