import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/widgets/busy_overlay.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/export/application/canvas_export_service.dart';
import 'package:image_editor/features/export/application/export_notifier.dart';
import 'package:image_editor/features/export/application/watermark_renderer.dart';
import 'package:image_editor/features/export/application/watermark_settings_notifier.dart';
import 'package:image_editor/features/export/data/watermark_settings_repository.dart';
import 'package:image_editor/features/export/domain/models/models.dart';
import 'package:image_editor/features/export/presentation/widgets/export_success_sheet.dart';
import 'package:image_editor/features/segmentation/presentation/background_removal_prompt.dart';
import 'package:image_editor/features/tutorial/tutorial.dart';

/// Exports a project: a live preview of the design (with the brand
/// watermark exactly as it will be saved), format and quality, the
/// watermark's settings, and the two actions: Export (no watermark) and
/// Export with watermark. Watermark changes are remembered automatically.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, required this.project});

  final ProjectModel project;

  static Future<void> show(BuildContext context, ProjectModel project) {
    return Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => ExportScreen(project: project)));
  }

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  static const List<int> textColors = <int>[0xFFFFFFFF, 0xFF000000, 0xFFC2410C, 0xFFEF4444, 0xFF0F766E];
  static const Duration saveDelay = Duration(milliseconds: 400);

  // Resolved in initState: dispose() must not use ref.
  late final CanvasExportService _service;
  late final WatermarkSettingsNotifier _settings;
  late final TextEditingController _text = TextEditingController();

  ExportFormat _format = ExportFormat.png;
  ExportResolution _resolution = ExportResolution.standard;
  int _jpegQuality = 92;

  WatermarkConfig _watermark = const WatermarkConfig();
  bool _watermarkLoaded = false;
  bool _showWatermark = true;
  String? _logoError;
  Timer? _saveTimer;
  bool _unsaved = false;

  ui.Image? _preview;
  bool _previewFailed = false;
  ui.Image? _logo;
  String? _logoPath;

  Size get _canvasSize => Size(widget.project.canvasWidth, widget.project.canvasHeight);

  @override
  void initState() {
    super.initState();
    _service = ref.read(canvasExportServiceProvider);
    _settings = ref.read(watermarkSettingsProvider.notifier);
    _renderPreview();
    ref
        .read(watermarkSettingsProvider.future)
        .then(
          (config) {
            if (!mounted) return;
            _text.text = config.text;
            setState(() {
              _watermark = config;
              _watermarkLoaded = true;
            });
            _loadLogo();
          },
          onError: (Object _) {
            if (mounted) setState(() => _watermarkLoaded = true);
          },
        );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (_unsaved) unawaited(_settings.save(_watermark));
    _text.dispose();
    _preview?.dispose();
    _logo?.dispose();
    super.dispose();
  }

  Future<void> _renderPreview() async {
    try {
      final image = await _service.renderPreview(widget.project, maxEdge: 1080.0);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _preview = image);
    } catch (_) {
      if (mounted) setState(() => _previewFailed = true);
    }
  }

  /// Decodes the logo for the preview whenever its file changes.
  Future<void> _loadLogo() async {
    final path = _watermark.logoRelativePath;
    if (path == _logoPath) return;
    _logoPath = path;
    final logo = path == null ? null : await _service.loadWatermarkLogo(path);
    if (!mounted || _logoPath != path) {
      logo?.dispose();
      return;
    }
    final previous = _logo;
    setState(() => _logo = logo);
    previous?.dispose();
  }

  void _update(WatermarkConfig config) {
    setState(() => _watermark = config);
    _unsaved = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, _saveNow);
  }

  Future<void> _saveNow() async {
    _saveTimer?.cancel();
    if (!_unsaved) return;
    _unsaved = false;
    await _settings.save(_watermark);
  }

  Future<void> _pickLogo() async {
    try {
      final image = await BusyOverlay.during(
        context,
        message: 'Importing logo…',
        task: (showBusy) => _settings.pickLogoImage(onPicked: showBusy),
      );
      if (image == null || !mounted) return;
      final cutout = await BackgroundRemovalPrompt.show(context, imageBytes: image.bytes);
      final path = await _settings.storeLogo(image, cutoutPng: cutout);
      if (!mounted) return;
      _logoError = null;
      _update(_watermark.copyWith(type: WatermarkType.logo, logoRelativePath: path));
      await _loadLogo();
    } on LogoImportException catch (error) {
      if (mounted) setState(() => _logoError = error.message);
    }
  }

  String _sizeLabel(ExportResolution resolution) {
    final size = resolution.outputSizeFor(_canvasSize);
    return '${size.width.round()} × ${size.height.round()} px';
  }

  Future<void> _export({required bool withWatermark}) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (withWatermark) await _saveNow();
    final config = ExportConfig(
      format: _format,
      resolution: _resolution,
      jpegQuality: _jpegQuality,
      watermark: _watermark.copyWith(isEnabled: withWatermark),
    );

    final exporter = ref.read(exportProvider.notifier);
    final saved = await exporter.exportProject(project: widget.project, config: config);
    if (!mounted) return;

    if (saved) {
      final bytes = ref.read(exportProvider).exportedBytes!;
      navigator.pop();
      await ExportSuccessSheet.show(navigator.context, bytes);
    } else {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ref.read(exportProvider).error ?? 'Export failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isExporting = ref.watch(exportProvider.select((s) => s.isExporting));
    final media = MediaQuery.of(context);

    return TourHost(
      autoStart: Tours.export,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Export'),
          actions: [
            IconButton(
              key: const ValueKey('export_help'),
              tooltip: 'Show the tour',
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => ref.read(tourRunnerProvider).run(context, Tours.export, force: true),
            ),
          ],
        ),
        body: Column(
          children: [
            // Pinned, so the watermark stays visible while it is adjusted.
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 4.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: media.size.height * 0.32),
                  child: TourAnchor(
                    id: TourAnchors.exportPreview,
                    child: AspectRatio(
                      aspectRatio: _canvasSize.width / _canvasSize.height,
                      child: _ExportPreview(
                        canvasSize: _canvasSize,
                        preview: _preview,
                        failed: _previewFailed,
                        watermark: _showWatermark && _watermarkLoaded ? _watermark : null,
                        logo: _logo,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _settingsList(theme, colors)),
          ],
        ),
        bottomNavigationBar: _actions(theme, colors, isExporting),
      ),
    );
  }

  Widget _settingsList(ThemeData theme, ColorScheme colors) {
    // A plain scroll view (not a lazy list): every row is built, so tour
    // targets further down exist and can be scrolled to.
    return SingleChildScrollView(
      key: const ValueKey('export_screen_list'),
      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const ValueKey('preview_watermark_switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Show watermark in preview'),
            value: _showWatermark,
            onChanged: (value) => setState(() => _showWatermark = value),
          ),
          const SizedBox(height: 8.0),
          Text('Format', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8.0),
          SegmentedButton<ExportFormat>(
            key: const ValueKey('export_format'),
            segments: const [
              ButtonSegment(value: ExportFormat.png, label: Text('PNG')),
              ButtonSegment(value: ExportFormat.jpeg, label: Text('JPEG')),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          if (_format == ExportFormat.jpeg) ...[
            const SizedBox(height: 8.0),
            Text('JPEG quality $_jpegQuality', style: theme.textTheme.labelLarge),
            Slider(
              key: const ValueKey('jpeg_quality_slider'),
              value: _jpegQuality.toDouble(),
              min: 60,
              max: 100,
              divisions: 40,
              onChanged: (v) => setState(() => _jpegQuality = v.round()),
            ),
          ],
          const SizedBox(height: 16.0),
          Text('Quality', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8.0),
          SegmentedButton<ExportResolution>(
            key: const ValueKey('export_resolution'),
            segments: [
              for (final resolution in ExportResolution.values)
                ButtonSegment(
                  value: resolution,
                  label: Text(resolution.label, key: ValueKey('res_${resolution.name}')),
                ),
            ],
            selected: {_resolution},
            onSelectionChanged: (s) => setState(() => _resolution = s.first),
          ),
          const SizedBox(height: 6.0),
          Text(
            _sizeLabel(_resolution),
            key: const ValueKey('export_size_label'),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const Divider(height: 40.0),
          Text('Brand watermark', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4.0),
          Text(
            'Remembered for next time. It is added only when you tap Export with watermark.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12.0),
          TourAnchor(
            id: TourAnchors.watermarkType,
            child: SegmentedButton<WatermarkType>(
              key: const ValueKey('watermark_type'),
              segments: [for (final type in WatermarkType.values) ButtonSegment(value: type, label: Text(type.label))],
              selected: {_watermark.type},
              onSelectionChanged: (s) => _update(_watermark.copyWith(type: s.first)),
            ),
          ),
          const SizedBox(height: 16.0),
          if (_watermark.type == WatermarkType.text) ...[
            TextField(
              key: const ValueKey('watermark_text_field'),
              controller: _text,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Watermark text'),
              onChanged: (value) => _update(_watermark.copyWith(text: value)),
            ),
            Text('Color', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 10.0,
              children: [
                for (final color in textColors)
                  GestureDetector(
                    key: ValueKey('watermark_color_$color'),
                    onTap: () => _update(_watermark.copyWith(colorValue: color)),
                    child: Container(
                      width: 36.0,
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color == _watermark.colorValue ? colors.primary : colors.outlineVariant,
                          width: color == _watermark.colorValue ? 3.0 : 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text('Size', style: theme.textTheme.labelLarge),
            Slider(
              key: const ValueKey('watermark_size_slider'),
              value: _watermark.fontSize.clamp(12.0, 96.0),
              min: 12.0,
              max: 96.0,
              onChanged: (v) => _update(_watermark.copyWith(fontSize: v)),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 64.0,
                  height: 64.0,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _LogoThumbnail(relativePath: _watermark.logoRelativePath),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('pick_logo_button'),
                    onPressed: _pickLogo,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(_watermark.logoRelativePath == null ? 'Choose logo' : 'Change logo'),
                  ),
                ),
              ],
            ),
            if (_logoError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_logoError!, style: TextStyle(color: colors.error)),
              ),
            const SizedBox(height: 12.0),
            Text('Size', style: theme.textTheme.labelLarge),
            Slider(
              key: const ValueKey('logo_size_slider'),
              value: _watermark.logoScale.clamp(WatermarkConfig.minLogoScale, WatermarkConfig.maxLogoScale),
              min: WatermarkConfig.minLogoScale,
              max: WatermarkConfig.maxLogoScale,
              onChanged: (v) => _update(_watermark.copyWith(logoScale: v)),
            ),
          ],
          const SizedBox(height: 8.0),
          Text('Position', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8.0),
          TourAnchor(
            id: TourAnchors.watermarkPosition,
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                for (final position in WatermarkPosition.values)
                  ChoiceChip(
                    key: ValueKey('watermark_position_${position.name}'),
                    label: Text(position.label),
                    selected: _watermark.position == position,
                    onSelected: (_) => _update(_watermark.copyWith(position: position)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          TourAnchor(
            id: TourAnchors.watermarkOpacity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Opacity ${(100 * _watermark.opacity).round()}%', style: theme.textTheme.labelLarge),
                Slider(
                  key: const ValueKey('watermark_opacity_slider'),
                  value: _watermark.opacity,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (v) => _update(_watermark.copyWith(opacity: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(ThemeData theme, ColorScheme colors, bool isExporting) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isExporting) ...[
              const LinearProgressIndicator(key: ValueKey('export_progress')),
              const SizedBox(height: 12.0),
            ],
            TourAnchor(
              id: TourAnchors.exportActions,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('export_without_watermark'),
                    onPressed: isExporting ? null : () => _export(withWatermark: false),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export'),
                  ),
                  const SizedBox(height: 8.0),
                  OutlinedButton.icon(
                    key: const ValueKey('export_with_watermark'),
                    onPressed: isExporting || !_watermark.isReady ? null : () => _export(withWatermark: true),
                    icon: const Icon(Icons.branding_watermark_outlined),
                    label: const Text('Export with watermark'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              _watermark.isReady
                  ? 'Saved to your Gallery in the Chitred album.'
                  : _watermark.type == WatermarkType.logo
                  ? 'Choose a logo to export with a watermark.'
                  : 'Type a watermark text to export with a watermark.',
              key: const ValueKey('export_footer'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rendered design with the watermark painted live on top.
class _ExportPreview extends StatelessWidget {
  const _ExportPreview({
    required this.canvasSize,
    required this.preview,
    required this.failed,
    required this.watermark,
    required this.logo,
  });

  final Size canvasSize;
  final ui.Image? preview;
  final bool failed;
  final WatermarkConfig? watermark;
  final ui.Image? logo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = preview;
    final mark = watermark;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12.0, offset: Offset(0, 4))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            RawImage(key: const ValueKey('export_preview_image'), image: image, fit: BoxFit.fill)
          else
            ColoredBox(
              color: colors.surfaceContainerHighest,
              child: Center(
                child: failed
                    ? const Icon(Icons.broken_image_outlined)
                    : const CircularProgressIndicator(key: ValueKey('export_preview_loading')),
              ),
            ),
          if (mark != null)
            CustomPaint(
              key: const ValueKey('export_preview_watermark'),
              painter: WatermarkPreviewPainter(canvasSize: canvasSize, watermark: mark, logo: logo),
            ),
        ],
      ),
    );
  }
}

/// Paints [watermark] scaled from canvas units to the preview's size.
class WatermarkPreviewPainter extends CustomPainter {
  const WatermarkPreviewPainter({required this.canvasSize, required this.watermark, this.logo});

  final Size canvasSize;
  final WatermarkConfig watermark;
  final ui.Image? logo;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / canvasSize.width, size.height / canvasSize.height);
    WatermarkRenderer.paint(canvas, canvasSize, watermark, logo: logo);
    canvas.restore();
  }

  @override
  bool shouldRepaint(WatermarkPreviewPainter oldDelegate) =>
      oldDelegate.watermark != watermark || oldDelegate.logo != logo || oldDelegate.canvasSize != canvasSize;
}

class _LogoThumbnail extends ConsumerWidget {
  const _LogoThumbnail({required this.relativePath});

  final String? relativePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = relativePath;
    if (path == null) return const Icon(Icons.image_outlined);
    return FutureBuilder<File>(
      future: ref.watch(watermarkSettingsRepositoryProvider).resolve(path),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) return const SizedBox.shrink();
        return Image.file(
          file,
          key: ValueKey(path),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        );
      },
    );
  }
}
