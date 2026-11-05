import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/fonts/application/application.dart';
import 'package:image_editor/features/fonts/data/google_fonts_client.dart';
import 'package:image_editor/features/fonts/domain/domain.dart';

/// Human-readable file size, e.g. `128 KB`.
String formatFontSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.round()} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}

/// Lets the user choose a font for text: the built-in default, installed
/// fonts (downloaded or imported), or new downloads from the curated catalog.
///
/// Returns the chosen family, or null if dismissed.
class FontPickerSheet extends StatelessWidget {
  const FontPickerSheet({super.key, required this.currentFamily});

  final String currentFamily;

  static Future<String?> show(BuildContext context, {required String currentFamily}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => FontPickerSheet(currentFamily: currentFamily),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        // A local messenger keeps snackbars visible above the sheet.
        return ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const SizedBox(height: 12.0),
                  Container(
                    width: 32.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Fonts', style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ),
                  const TabBar(
                    tabs: [
                      Tab(key: ValueKey('tab_my_fonts'), text: 'My fonts'),
                      Tab(key: ValueKey('tab_download'), text: 'Download'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _MyFontsTab(currentFamily: currentFamily),
                        _DownloadTab(currentFamily: currentFamily),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Downloads [font]; reports failures in a snackbar. Returns true on success.
Future<bool> _download(BuildContext context, WidgetRef ref, CatalogFont font) async {
  try {
    await ref.read(fontLibraryProvider.notifier).download(font);
    return true;
  } on FontDownloadException {
    if (context.mounted) {
      _showMessage(context, 'Could not download ${font.family}. Check your connection and try again.');
    }
    return false;
  }
}

class _MyFontsTab extends ConsumerWidget {
  const _MyFontsTab({required this.currentFamily});

  final String currentFamily;

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final picked = await ref.read(fontFilePickerProvider).pick();
    if (picked == null || !context.mounted) return;
    try {
      final entry = await ref
          .read(fontLibraryProvider.notifier)
          .importFile(fileName: picked.name, bytes: picked.bytes);
      if (context.mounted) _showMessage(context, '${entry.displayName} added to your fonts.');
    } on FontImportException catch (error) {
      if (context.mounted) _showMessage(context, error.message);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, FontEntry entry) async {
    final notifier = ref.read(fontLibraryProvider.notifier);
    final uses = await notifier.usageCount(entry.family);
    if (!context.mounted) return;

    final restore = entry.isImported ? 'import it again' : 'download it again';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${entry.displayName}?'),
        content: Text(
          uses > 0
              ? 'Used in $uses ${uses == 1 ? 'project' : 'projects'}. That text will show '
                  'in the default font until you $restore.'
              : 'You can $restore at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm_delete_font'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await notifier.delete(entry);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(fontLibraryProvider).value ?? const FontLibraryState();
    final colors = Theme.of(context).colorScheme;
    final missing = !library.isInstalled(currentFamily);
    final missingCatalogFont =
        curatedFonts.where((font) => font.family == currentFamily).firstOrNull;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24.0),
      children: [
        if (missing)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0.0),
            child: Card(
              color: colors.errorContainer,
              child: ListTile(
                key: const ValueKey('missing_font_banner'),
                leading: Icon(Icons.font_download_off_outlined, color: colors.onErrorContainer),
                title: Text(
                  '${currentFamily.replaceFirst(FontLibraryNotifier.importedFamilyPrefix, '')} '
                  'is not installed',
                  style: TextStyle(color: colors.onErrorContainer),
                ),
                subtitle: Text(
                  missingCatalogFont != null
                      ? 'Download it to show this text in its font again.'
                      : 'Import the font file again to restore it.',
                  style: TextStyle(color: colors.onErrorContainer),
                ),
                trailing: missingCatalogFont == null
                    ? null
                    : TextButton(
                        key: const ValueKey('redownload_missing_font'),
                        onPressed: () => _download(context, ref, missingCatalogFont),
                        child: const Text('Download'),
                      ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
          child: OutlinedButton.icon(
            key: const ValueKey('import_font_button'),
            onPressed: () => _import(context, ref),
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Import font (.ttf / .otf)'),
          ),
        ),
        _FontTile(
          key: const ValueKey('font_row_default'),
          title: 'Default',
          // Text layers render the default in the system font, not the app's
          // UI font, so preview it that way.
          titleFamily: systemDefaultFontFamily,
          subtitle: 'Built in',
          isSelected: currentFamily == systemDefaultFontFamily,
          onTap: () => Navigator.of(context).pop(systemDefaultFontFamily),
        ),
        for (final entry in library.fonts)
          _FontTile(
            key: ValueKey('font_row_${entry.family}'),
            title: entry.displayName,
            titleFamily: entry.family,
            subtitle:
                '${entry.isImported ? 'Imported' : 'Downloaded'} · ${formatFontSize(entry.sizeBytes)}',
            isSelected: currentFamily == entry.family,
            onTap: () => Navigator.of(context).pop(entry.family),
            trailing: IconButton(
              key: ValueKey('delete_font_${entry.family}'),
              tooltip: 'Delete font',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _delete(context, ref, entry),
            ),
          ),
        if (library.fonts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'No fonts yet. Download one from the catalog or import your own.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class _FontTile extends StatelessWidget {
  const _FontTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.titleFamily,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  /// Family to render the title in; null for the default font.
  final String? titleFamily;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      selected: isSelected,
      selectedTileColor: colors.primaryContainer.withValues(alpha: 0.5),
      leading: Icon(
        isSelected ? Icons.check_circle_rounded : Icons.text_fields_rounded,
        color: isSelected ? colors.primary : colors.onSurfaceVariant,
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontFamily: titleFamily, fontSize: 20.0, color: colors.onSurface),
      ),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _DownloadTab extends ConsumerStatefulWidget {
  const _DownloadTab({required this.currentFamily});

  final String currentFamily;

  @override
  ConsumerState<_DownloadTab> createState() => _DownloadTabState();
}

class _DownloadTabState extends ConsumerState<_DownloadTab> {
  String _query = '';
  FontScript? _script;

  List<CatalogFont> get _visibleFonts {
    final query = _query.trim().toLowerCase();
    return curatedFonts
        .where((font) => _script == null || font.script == _script)
        .where((font) => query.isEmpty || font.family.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final reachability = ref.watch(fontServerReachabilityProvider);

    return switch (reachability) {
      AsyncData(value: true) => _buildCatalog(context),
      AsyncData(value: false) || AsyncError() => _OfflineView(
          onRetry: () => ref.read(fontServerReachabilityProvider.notifier).retry(),
        ),
      _ => const Center(
          key: ValueKey('checking_connection'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16.0),
              Text('Checking connection…'),
            ],
          ),
        ),
    };
  }

  Widget _buildCatalog(BuildContext context) {
    final library = ref.watch(fontLibraryProvider).value ?? const FontLibraryState();
    final fonts = _visibleFonts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
          child: TextField(
            key: const ValueKey('font_search'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search fonts',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            // All script filters stay visible: a scrolling row hid some
            // languages on narrow phones.
            child: Wrap(
              spacing: 8.0,
              children: [
                for (final script in <FontScript?>[null, ...FontScript.values])
                  ChoiceChip(
                    key: ValueKey('script_${script?.name ?? 'all'}'),
                    label: Text(script?.label ?? 'All'),
                    selected: _script == script,
                    onSelected: (_) => setState(() => _script = script),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: fonts.isEmpty
              ? const Center(child: Text('No fonts match your search.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  itemCount: fonts.length,
                  itemBuilder: (context, index) => _CatalogRow(
                    font: fonts[index],
                    isInstalled: library.isInstalled(fonts[index].family),
                    isSelected: fonts[index].family == widget.currentFamily,
                    isDownloading: library.downloading.containsKey(fonts[index].family),
                    progress: library.downloading[fonts[index].family],
                  ),
                ),
        ),
      ],
    );
  }
}

class _CatalogRow extends ConsumerWidget {
  const _CatalogRow({
    required this.font,
    required this.isInstalled,
    required this.isSelected,
    required this.isDownloading,
    required this.progress,
  });

  final CatalogFont font;
  final bool isInstalled;
  final bool isSelected;
  final bool isDownloading;
  final double? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final previewFamily = ref.watch(fontPreviewFamilyProvider(font.family)).value;

    final Widget trailing;
    if (isInstalled) {
      trailing = Icon(Icons.check_rounded, color: colors.primary, semanticLabel: 'Installed');
    } else if (isDownloading) {
      trailing = SizedBox(
        width: 24.0,
        height: 24.0,
        child: CircularProgressIndicator(strokeWidth: 2.5, value: progress),
      );
    } else {
      trailing = IconButton(
        key: ValueKey('download_${font.family}'),
        tooltip: 'Download',
        icon: const Icon(Icons.download_rounded),
        onPressed: () => _download(context, ref, font),
      );
    }

    return ListTile(
      key: ValueKey('catalog_row_${font.family}'),
      selected: isSelected,
      title: Text(
        font.family,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontFamily: previewFamily, fontSize: 20.0, color: colors.onSurface),
      ),
      subtitle: Text('${font.category.label} · ${font.script.label}'
          '${isInstalled ? ' · Installed' : ''}'),
      trailing: trailing,
      onTap: isDownloading
          ? null
          : () async {
              // Tapping a row picks the font, downloading it first if needed.
              if (isInstalled || await _download(context, ref, font)) {
                if (context.mounted) Navigator.of(context).pop(font.family);
              }
            },
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      key: const ValueKey('offline_view'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48.0, color: colors.onSurfaceVariant),
            const SizedBox(height: 16.0),
            Text('No internet connection', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8.0),
            Text(
              'Connect to Wi-Fi or mobile data with internet access to download fonts. '
              'Your installed fonts keep working offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20.0),
            FilledButton.icon(
              key: const ValueKey('retry_connection'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
