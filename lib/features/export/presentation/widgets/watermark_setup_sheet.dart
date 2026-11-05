import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/core/widgets/busy_overlay.dart';
import 'package:image_editor/features/export/application/watermark_settings_notifier.dart';
import 'package:image_editor/features/export/data/watermark_settings_repository.dart';
import 'package:image_editor/features/export/domain/models/watermark_config.dart';
import 'package:image_editor/features/segmentation/presentation/background_removal_prompt.dart';

/// Sets up the brand watermark once; it is then offered on every export.
class WatermarkSetupSheet extends ConsumerStatefulWidget {
  const WatermarkSetupSheet({super.key, required this.initial});

  final WatermarkConfig initial;

  /// Shows the sheet; returns the saved watermark, or null if cancelled.
  static Future<WatermarkConfig?> show(BuildContext context, WatermarkConfig initial) {
    return showModalBottomSheet<WatermarkConfig>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WatermarkSetupSheet(initial: initial),
    );
  }

  @override
  ConsumerState<WatermarkSetupSheet> createState() => _WatermarkSetupSheetState();
}

class _WatermarkSetupSheetState extends ConsumerState<WatermarkSetupSheet> {
  static const List<int> textColors = <int>[0xFFFFFFFF, 0xFF000000, 0xFF4F46E5, 0xFFEF4444];

  late WatermarkConfig _config = widget.initial;
  late final TextEditingController _text = TextEditingController(text: widget.initial.text);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final settings = ref.read(watermarkSettingsProvider.notifier);
    try {
      final image = await BusyOverlay.during(
        context,
        message: 'Importing logo…',
        task: (showBusy) => settings.pickLogoImage(onPicked: showBusy),
      );
      if (image == null || !mounted) return;
      final cutout = await BackgroundRemovalPrompt.show(context, imageBytes: image.bytes);
      final path = await settings.storeLogo(image, cutoutPng: cutout);
      if (mounted) {
        setState(() {
          _config = _config.copyWith(type: WatermarkType.logo, logoRelativePath: path);
          _error = null;
        });
      }
    } on LogoImportException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _save() async {
    await ref.read(watermarkSettingsProvider.notifier).save(_config);
    if (mounted) Navigator.of(context).pop(_config);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
            children: [
              Text('Brand watermark', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4.0),
              Text(
                'Set it up once. Every export lets you choose to include it.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16.0),
              SegmentedButton<WatermarkType>(
                key: const ValueKey('watermark_type'),
                segments: [
                  for (final type in WatermarkType.values)
                    ButtonSegment(value: type, label: Text(type.label)),
                ],
                selected: {_config.type},
                onSelectionChanged: (s) => setState(() => _config = _config.copyWith(type: s.first)),
              ),
              const SizedBox(height: 16.0),
              if (_config.type == WatermarkType.text) ...[
                TextField(
                  key: const ValueKey('watermark_text_field'),
                  controller: _text,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Watermark text'),
                  onChanged: (value) => setState(() => _config = _config.copyWith(text: value)),
                ),
                Text('Color', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 10.0,
                  children: [
                    for (final color in textColors)
                      GestureDetector(
                        key: ValueKey('watermark_color_$color'),
                        onTap: () => setState(() => _config = _config.copyWith(colorValue: color)),
                        child: Container(
                          width: 34.0,
                          height: 34.0,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color == _config.colorValue ? colors.primary : colors.outlineVariant,
                              width: color == _config.colorValue ? 3.0 : 1.0,
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
                  value: _config.fontSize.clamp(12.0, 72.0),
                  min: 12.0,
                  max: 72.0,
                  onChanged: (v) => setState(() => _config = _config.copyWith(fontSize: v)),
                ),
              ] else ...[
                Row(
                  children: [
                    Container(
                      width: 72.0,
                      height: 72.0,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _LogoPreview(relativePath: _config.logoRelativePath),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('pick_logo_button'),
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(_config.logoRelativePath == null ? 'Choose logo' : 'Change logo'),
                      ),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_error!, style: TextStyle(color: colors.error)),
                  ),
              ],
              const SizedBox(height: 16.0),
              Text('Position', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  for (final position in WatermarkPosition.values)
                    ChoiceChip(
                      key: ValueKey('watermark_position_${position.name}'),
                      label: Text(position.label),
                      selected: _config.position == position,
                      onSelected: (_) => setState(() => _config = _config.copyWith(position: position)),
                    ),
                ],
              ),
              const SizedBox(height: 12.0),
              Text('Opacity ${(100 * _config.opacity).round()}%', style: theme.textTheme.labelLarge),
              Slider(
                key: const ValueKey('watermark_opacity_slider'),
                value: _config.opacity,
                min: 0.1,
                max: 1.0,
                onChanged: (v) => setState(() => _config = _config.copyWith(opacity: v)),
              ),
              const SizedBox(height: 8.0),
              FilledButton(
                key: const ValueKey('save_watermark'),
                onPressed: _config.isReady ? _save : null,
                child: const Text('Save watermark'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoPreview extends ConsumerWidget {
  const _LogoPreview({required this.relativePath});

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
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        );
      },
    );
  }
}
