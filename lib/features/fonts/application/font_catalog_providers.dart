import 'package:image_editor/features/fonts/application/font_library_notifier.dart';
import 'package:image_editor/features/fonts/data/google_fonts_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_catalog_providers.g.dart';

/// Whether the font server is reachable. Checked again each time the
/// download list is opened (auto-disposed) or when the user taps Retry.
@riverpod
class FontServerReachability extends _$FontServerReachability {
  @override
  Future<bool> build() => ref.watch(googleFontsClientProvider).isReachable();

  Future<void> retry() async {
    final client = ref.read(googleFontsClientProvider);
    state = const AsyncLoading<bool>();
    final reachable = await client.isReachable();
    if (ref.mounted) state = AsyncData(reachable);
  }
}

/// Prefix for families registered only to preview catalog fonts.
const String previewFamilyPrefix = 'preview:';

/// Family name to render [family]'s name in, or null if no preview could be
/// loaded (the UI then uses the default font).
///
/// Installed fonts preview with themselves; others download a subset of
/// about 2 KB holding just the glyphs of the name. Results are cached for the
/// session (keep-alive); that costs ~110 KB for the whole catalog.
@Riverpod(keepAlive: true)
Future<String?> fontPreviewFamily(Ref ref, String family) async {
  final library = await ref.watch(fontLibraryProvider.future);
  if (library.isInstalled(family)) return family;

  final client = ref.read(googleFontsClientProvider);
  final register = ref.read(fontRegistrarProvider);
  try {
    final bytes = await client.downloadPreview(family, family);
    final previewFamily = '$previewFamilyPrefix$family';
    await register(bytes, previewFamily);
    return previewFamily;
  } on Object {
    return null;
  }
}
