import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/export/application/export_notifier.dart';
import 'package:image_editor/features/export/application/watermark_settings_notifier.dart';
import 'package:image_editor/features/export/domain/models/models.dart';
import 'package:image_editor/features/export/presentation/widgets/export_success_sheet.dart';
import 'package:image_editor/features/export/presentation/widgets/watermark_setup_sheet.dart';

/// Export options for a project. The main action exports without a
/// watermark; exporting with the remembered brand watermark is offered as
/// the alternative on every export.
class ExportSheet extends ConsumerStatefulWidget {
  const ExportSheet({super.key, required this.project});

  final ProjectModel project;

  static Future<void> show(BuildContext context, ProjectModel project) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExportSheet(project: project),
    );
  }

  @override
  ConsumerState<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<ExportSheet> {
  ExportFormat _format = ExportFormat.png;
  ExportResolution _resolution = ExportResolution.standard;
  int _jpegQuality = 92;

  Size get _canvasSize => Size(widget.project.canvasWidth, widget.project.canvasHeight);

  String _sizeLabel(ExportResolution resolution) {
    final size = resolution.outputSizeFor(_canvasSize);
    return '${size.width.round()} × ${size.height.round()} px';
  }

  Future<void> _export({required bool withWatermark}) async {
    // Captured before awaiting: the success sheet opens after this one closes.
    final navigator = Navigator.of(context);
    final watermark = ref.read(watermarkSettingsProvider).value ?? const WatermarkConfig();
    final config = ExportConfig(
      format: _format,
      resolution: _resolution,
      jpegQuality: _jpegQuality,
      watermark: watermark.copyWith(isEnabled: withWatermark),
    );

    final saved = await ref
        .read(exportProvider.notifier)
        .exportProject(project: widget.project, config: config);
    if (!mounted) return;

    if (saved) {
      final bytes = ref.read(exportProvider).exportedBytes!;
      navigator.pop();
      await ExportSuccessSheet.show(navigator.context, bytes);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ref.read(exportProvider).error ?? 'Export failed.')));
    }
  }

  Future<void> _editWatermark(WatermarkConfig current) => WatermarkSetupSheet.show(context, current);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isExporting = ref.watch(exportProvider.select((s) => s.isExporting));
    final watermark = ref.watch(watermarkSettingsProvider).value ?? const WatermarkConfig();

    return ScaffoldMessenger(
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                children: [
                  Text('Export', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16.0),
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
                  RadioGroup<ExportResolution>(
                    groupValue: _resolution,
                    onChanged: (v) => setState(() => _resolution = v ?? _resolution),
                    child: Column(
                      children: [
                        for (final resolution in ExportResolution.values)
                          RadioListTile<ExportResolution>(
                            key: ValueKey('res_${resolution.name}'),
                            contentPadding: EdgeInsets.zero,
                            value: resolution,
                            title: Text(resolution.label),
                            subtitle: Text(_sizeLabel(resolution)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Card(
                    child: ListTile(
                      key: const ValueKey('watermark_card'),
                      leading: const Icon(Icons.branding_watermark_outlined),
                      title: const Text('Brand watermark'),
                      subtitle: Text(
                        !watermark.isReady
                            ? 'Not set up'
                            : watermark.type == WatermarkType.text
                                ? '"${watermark.text}" · ${watermark.position.label}'
                                : 'Logo · ${watermark.position.label}',
                      ),
                      trailing: TextButton(
                        key: const ValueKey('edit_watermark'),
                        onPressed: () => _editWatermark(watermark),
                        child: Text(watermark.isReady ? 'Edit' : 'Set up'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  if (isExporting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    FilledButton.icon(
                      key: const ValueKey('export_without_watermark'),
                      onPressed: () => _export(withWatermark: false),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Export'),
                    ),
                    const SizedBox(height: 8.0),
                    OutlinedButton.icon(
                      key: const ValueKey('export_with_watermark'),
                      onPressed: watermark.isReady
                          ? () => _export(withWatermark: true)
                          : () => _editWatermark(watermark),
                      icon: const Icon(Icons.branding_watermark_outlined),
                      label: Text(
                        watermark.isReady ? 'Export with watermark' : 'Set up watermark',
                      ),
                    ),
                  ],
                  const SizedBox(height: 4.0),
                  Text(
                    'Saved to your Gallery in the Chitred album.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
