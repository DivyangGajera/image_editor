import 'package:image_editor/features/fonts/application/font_library_notifier.dart';
import 'package:image_editor/features/fonts/domain/font_entry.dart';

/// Font library test double with a fixed set of installed families and no
/// storage, engine or network access.
class FixedFontLibrary extends FontLibraryNotifier {
  FixedFontLibrary(this.families);

  final List<String> families;

  @override
  Future<FontLibraryState> build() async => FontLibraryState(
        fonts: [
          for (final family in families)
            FontEntry(
              id: family,
              family: family,
              displayName: family.replaceFirst(FontLibraryNotifier.importedFamilyPrefix, ''),
              isImported: family.startsWith(FontLibraryNotifier.importedFamilyPrefix),
              relativePath: 'fonts/${family.hashCode}.ttf',
              sizeBytes: 1024,
              addedAt: DateTime(2026),
            ),
        ],
      );
}
