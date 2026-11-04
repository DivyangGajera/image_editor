// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'projects_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All saved projects, most recently edited first, plus project management.

@ProviderFor(ProjectsNotifier)
final projectsProvider = ProjectsNotifierProvider._();

/// All saved projects, most recently edited first, plus project management.
final class ProjectsNotifierProvider
    extends $AsyncNotifierProvider<ProjectsNotifier, List<ProjectModel>> {
  /// All saved projects, most recently edited first, plus project management.
  ProjectsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectsNotifierHash();

  @$internal
  @override
  ProjectsNotifier create() => ProjectsNotifier();
}

String _$projectsNotifierHash() => r'7e753e18751ed23d8f865b59492c94b605fbfd04';

/// All saved projects, most recently edited first, plus project management.

abstract class _$ProjectsNotifier extends $AsyncNotifier<List<ProjectModel>> {
  FutureOr<List<ProjectModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ProjectModel>>, List<ProjectModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ProjectModel>>, List<ProjectModel>>,
              AsyncValue<List<ProjectModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
