import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_editor/core/utils/app_logger.dart';
import 'package:image_editor/features/canvas/data/project_repository.dart';
import 'package:image_editor/features/fonts/data/font_repository.dart';
import 'package:image_editor/features/fonts/data/google_fonts_client.dart';
import 'package:image_editor/features/fonts/domain/domain.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_library_notifier.g.dart';

/// Registers font bytes with the engine under a family name.
typedef FontRegistrar = Future<void> Function(Uint8List bytes, String family);

/// Default [FontRegistrar] using Flutter's runtime font loading.
Future<void> registerFontWithEngine(Uint8List bytes, String family) =>
    ui.loadFontFromList(bytes, fontFamily: family);

/// Engine registration used by the font library; overridden in tests.
@Riverpod(keepAlive: true)
FontRegistrar fontRegistrar(Ref ref) => registerFontWithEngine;

/// Thrown when a picked file cannot be imported as a font.
class FontImportException implements Exception {
  const FontImportException(this.message);
  final String message;

  @override
  String toString() => 'FontImportException: $message';
}

/// The installed fonts plus downloads in progress.
@immutable
class FontLibraryState {
  const FontLibraryState({
    this.fonts = const <FontEntry>[],
    this.downloading = const <String, double?>{},
  });

  /// Installed fonts, sorted by display name.
  final List<FontEntry> fonts;

  /// Families being downloaded, with progress 0..1 (null while unknown).
  final Map<String, double?> downloading;

  /// Families that can be rendered right now, including the built-in default.
  Set<String> get installedFamilies => {
        systemDefaultFontFamily,
        for (final font in fonts) font.family,
      };

  bool isInstalled(String family) => installedFamilies.contains(family);

  FontEntry? entryFor(String family) =>
      fonts.where((font) => font.family == family).firstOrNull;

  FontLibraryState copyWith({
    List<FontEntry>? fonts,
    Map<String, double?>? downloading,
  }) {
    return FontLibraryState(
      fonts: fonts ?? this.fonts,
      downloading: downloading ?? this.downloading,
    );
  }
}

/// App-wide font library: installed fonts are registered with the engine at
/// startup, and fonts can be downloaded from the catalog, imported from a
/// file, or deleted. Persists across app restarts.
@Riverpod(keepAlive: true)
class FontLibraryNotifier extends _$FontLibraryNotifier {
  // Resolved once per build, so no method touches `ref` after an await.
  late FontRepository _fonts;
  late GoogleFontsClient _client;
  late FontRegistrar _register;
  late ProjectRepository _projects;

  /// Prefix for families of imported fonts, keeping them apart from catalog
  /// families with the same name.
  static const String importedFamilyPrefix = 'user:';

  @override
  Future<FontLibraryState> build() async {
    _fonts = ref.watch(fontRepositoryProvider);
    _client = ref.watch(googleFontsClientProvider);
    _register = ref.watch(fontRegistrarProvider);
    _projects = ref.watch(projectRepositoryProvider);

    final installed = <FontEntry>[];
    for (final entry in await _fonts.getAll()) {
      try {
        await _register(await _fonts.readBytes(entry), entry.family);
        installed.add(entry);
      } catch (error, stackTrace) {
        // A missing or corrupt file must not break the rest of the library.
        AppLogger.error(
          'Skipping font ${entry.displayName}',
          tag: 'Fonts',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return FontLibraryState(fonts: installed);
  }

  FontLibraryState get _current => state.value ?? const FontLibraryState();

  /// Applies [change] to the state, unless this notifier was disposed while
  /// an operation was awaiting I/O (reading state would then throw).
  void _update(FontLibraryState Function(FontLibraryState current) change) {
    if (!ref.mounted) return;
    state = AsyncData(change(_current));
  }

  void _setProgress(String family, double? progress) {
    _update((s) => s.copyWith(downloading: {...s.downloading, family: progress}));
  }

  void _clearProgress(String family) {
    _update((s) => s.copyWith(downloading: {...s.downloading}..remove(family)));
  }

  void _addInstalled(FontEntry entry) {
    _update((s) {
      final fonts = [...s.fonts, entry]
        ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      return s.copyWith(fonts: fonts);
    });
  }

  /// Downloads [font] from the catalog and installs it. Text that used this
  /// family before (e.g. after a delete) renders with it again immediately.
  Future<FontEntry> download(CatalogFont font) async {
    final existing = _current.entryFor(font.family);
    if (existing != null) return existing;

    _setProgress(font.family, null);
    try {
      final bytes = await _client.downloadFont(
        font.family,
        onProgress: (received, total) {
          if (total != null && total > 0) _setProgress(font.family, received / total);
        },
      );
      await _register(bytes, font.family);
      final entry = await _fonts.save(
        family: font.family,
        displayName: font.family,
        isImported: false,
        bytes: bytes,
        format: FontFileFormat.trueType,
      );
      _clearProgress(font.family);
      _addInstalled(entry);
      return entry;
    } catch (_) {
      _clearProgress(font.family);
      rethrow;
    }
  }

  /// Installs a font file the user picked, including legacy (non-Unicode)
  /// fonts, which render exactly what is typed. The name comes from the file
  /// name; re-importing a file with the same name restores text that used it.
  Future<FontEntry> importFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final format = FontFileValidator.detect(bytes);
    if (format == null) {
      throw const FontImportException('This file is not a TTF or OTF font.');
    }

    final baseName = p.basenameWithoutExtension(fileName).trim();
    final displayName = baseName.isEmpty ? 'Imported font' : baseName;
    final family = '$importedFamilyPrefix$displayName';

    final existing = _current.entryFor(family);
    if (existing != null) return existing;

    await _register(bytes, family);
    final entry = await _fonts.save(
      family: family,
      displayName: displayName,
      isImported: true,
      bytes: bytes,
      format: format,
    );
    _addInstalled(entry);
    return entry;
  }

  /// Number of projects with text using [family], to warn before deleting.
  Future<int> usageCount(String family) async {
    final projects = await _projects.getAllProjects();
    return projects
        .where((project) => project.layers.any((l) => l is TextLayer && l.fontFamily == family))
        .length;
  }

  /// Removes [entry] from the library. Text using it falls back to the
  /// default font until the font is downloaded or imported again.
  Future<void> delete(FontEntry entry) async {
    await _fonts.delete(entry);
    _update((s) => s.copyWith(fonts: s.fonts.where((font) => font.id != entry.id).toList()));
  }
}
