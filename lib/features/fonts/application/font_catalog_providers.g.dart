// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the font server is reachable. Checked again each time the
/// download list is opened (auto-disposed) or when the user taps Retry.

@ProviderFor(FontServerReachability)
final fontServerReachabilityProvider = FontServerReachabilityProvider._();

/// Whether the font server is reachable. Checked again each time the
/// download list is opened (auto-disposed) or when the user taps Retry.
final class FontServerReachabilityProvider
    extends $AsyncNotifierProvider<FontServerReachability, bool> {
  /// Whether the font server is reachable. Checked again each time the
  /// download list is opened (auto-disposed) or when the user taps Retry.
  FontServerReachabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontServerReachabilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontServerReachabilityHash();

  @$internal
  @override
  FontServerReachability create() => FontServerReachability();
}

String _$fontServerReachabilityHash() =>
    r'253e88c8b920c034c772e49150d2fe587916f0de';

/// Whether the font server is reachable. Checked again each time the
/// download list is opened (auto-disposed) or when the user taps Retry.

abstract class _$FontServerReachability extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Family name to render [family]'s name in, or null if no preview could be
/// loaded (the UI then uses the default font).
///
/// Installed fonts preview with themselves; others download a subset of
/// about 2 KB holding just the glyphs of the name. Results are cached for the
/// session (keep-alive); that costs ~110 KB for the whole catalog.

@ProviderFor(fontPreviewFamily)
final fontPreviewFamilyProvider = FontPreviewFamilyFamily._();

/// Family name to render [family]'s name in, or null if no preview could be
/// loaded (the UI then uses the default font).
///
/// Installed fonts preview with themselves; others download a subset of
/// about 2 KB holding just the glyphs of the name. Results are cached for the
/// session (keep-alive); that costs ~110 KB for the whole catalog.

final class FontPreviewFamilyProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Family name to render [family]'s name in, or null if no preview could be
  /// loaded (the UI then uses the default font).
  ///
  /// Installed fonts preview with themselves; others download a subset of
  /// about 2 KB holding just the glyphs of the name. Results are cached for the
  /// session (keep-alive); that costs ~110 KB for the whole catalog.
  FontPreviewFamilyProvider._({
    required FontPreviewFamilyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fontPreviewFamilyProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fontPreviewFamilyHash();

  @override
  String toString() {
    return r'fontPreviewFamilyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return fontPreviewFamily(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FontPreviewFamilyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fontPreviewFamilyHash() => r'871b8413d9b07892f3a4e5125fdd5dc1ee783c7d';

/// Family name to render [family]'s name in, or null if no preview could be
/// loaded (the UI then uses the default font).
///
/// Installed fonts preview with themselves; others download a subset of
/// about 2 KB holding just the glyphs of the name. Results are cached for the
/// session (keep-alive); that costs ~110 KB for the whole catalog.

final class FontPreviewFamilyFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  FontPreviewFamilyFamily._()
    : super(
        retry: null,
        name: r'fontPreviewFamilyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Family name to render [family]'s name in, or null if no preview could be
  /// loaded (the UI then uses the default font).
  ///
  /// Installed fonts preview with themselves; others download a subset of
  /// about 2 KB holding just the glyphs of the name. Results are cached for the
  /// session (keep-alive); that costs ~110 KB for the whole catalog.

  FontPreviewFamilyProvider call(String family) =>
      FontPreviewFamilyProvider._(argument: family, from: this);

  @override
  String toString() => r'fontPreviewFamilyProvider';
}
