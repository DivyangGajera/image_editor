// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_model_installer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide [SubjectModelInstaller]; overridden in tests.

@ProviderFor(subjectModelInstaller)
final subjectModelInstallerProvider = SubjectModelInstallerProvider._();

/// App-wide [SubjectModelInstaller]; overridden in tests.

final class SubjectModelInstallerProvider
    extends
        $FunctionalProvider<
          SubjectModelInstaller,
          SubjectModelInstaller,
          SubjectModelInstaller
        >
    with $Provider<SubjectModelInstaller> {
  /// App-wide [SubjectModelInstaller]; overridden in tests.
  SubjectModelInstallerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subjectModelInstallerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subjectModelInstallerHash();

  @$internal
  @override
  $ProviderElement<SubjectModelInstaller> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubjectModelInstaller create(Ref ref) {
    return subjectModelInstaller(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubjectModelInstaller value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubjectModelInstaller>(value),
    );
  }
}

String _$subjectModelInstallerHash() =>
    r'b4b7bd5b6280cbc79759093aa7c1fa15dd187010';
