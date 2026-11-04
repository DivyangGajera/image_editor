// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_library_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Engine registration used by the font library; overridden in tests.

@ProviderFor(fontRegistrar)
final fontRegistrarProvider = FontRegistrarProvider._();

/// Engine registration used by the font library; overridden in tests.

final class FontRegistrarProvider
    extends $FunctionalProvider<FontRegistrar, FontRegistrar, FontRegistrar>
    with $Provider<FontRegistrar> {
  /// Engine registration used by the font library; overridden in tests.
  FontRegistrarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontRegistrarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontRegistrarHash();

  @$internal
  @override
  $ProviderElement<FontRegistrar> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FontRegistrar create(Ref ref) {
    return fontRegistrar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FontRegistrar value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FontRegistrar>(value),
    );
  }
}

String _$fontRegistrarHash() => r'6b6b5724ed7f21ecfe1421be8f5d2ce2e00e618c';

/// App-wide font library: installed fonts are registered with the engine at
/// startup, and fonts can be downloaded from the catalog, imported from a
/// file, or deleted. Persists across app restarts.

@ProviderFor(FontLibraryNotifier)
final fontLibraryProvider = FontLibraryNotifierProvider._();

/// App-wide font library: installed fonts are registered with the engine at
/// startup, and fonts can be downloaded from the catalog, imported from a
/// file, or deleted. Persists across app restarts.
final class FontLibraryNotifierProvider
    extends $AsyncNotifierProvider<FontLibraryNotifier, FontLibraryState> {
  /// App-wide font library: installed fonts are registered with the engine at
  /// startup, and fonts can be downloaded from the catalog, imported from a
  /// file, or deleted. Persists across app restarts.
  FontLibraryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontLibraryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontLibraryNotifierHash();

  @$internal
  @override
  FontLibraryNotifier create() => FontLibraryNotifier();
}

String _$fontLibraryNotifierHash() =>
    r'1ad12585ea135e42f5afd475c4aeb4eeb2f65f40';

/// App-wide font library: installed fonts are registered with the engine at
/// startup, and fonts can be downloaded from the catalog, imported from a
/// file, or deleted. Persists across app restarts.

abstract class _$FontLibraryNotifier extends $AsyncNotifier<FontLibraryState> {
  FutureOr<FontLibraryState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<FontLibraryState>, FontLibraryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FontLibraryState>, FontLibraryState>,
              AsyncValue<FontLibraryState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
