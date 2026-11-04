// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_thumbnail_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide singleton [ProjectThumbnailService].

@ProviderFor(projectThumbnailService)
final projectThumbnailServiceProvider = ProjectThumbnailServiceProvider._();

/// App-wide singleton [ProjectThumbnailService].

final class ProjectThumbnailServiceProvider
    extends
        $FunctionalProvider<
          ProjectThumbnailService,
          ProjectThumbnailService,
          ProjectThumbnailService
        >
    with $Provider<ProjectThumbnailService> {
  /// App-wide singleton [ProjectThumbnailService].
  ProjectThumbnailServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectThumbnailServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectThumbnailServiceHash();

  @$internal
  @override
  $ProviderElement<ProjectThumbnailService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProjectThumbnailService create(Ref ref) {
    return projectThumbnailService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectThumbnailService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectThumbnailService>(value),
    );
  }
}

String _$projectThumbnailServiceHash() =>
    r'c20c69d0a83d727beca044b7f6cd2cfec137e08f';
