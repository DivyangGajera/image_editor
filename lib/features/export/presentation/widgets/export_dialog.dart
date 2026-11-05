import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/domain/models/models.dart';
import 'package:image_editor/features/export/application/export_notifier.dart';
import 'package:image_editor/features/export/domain/models/models.dart';
import 'package:image_editor/features/export/presentation/widgets/watermark_config_view.dart';

/// Modal dialog allowing the user to configure format, resolution, watermarks,
/// and trigger high-resolution headless canvas export.
class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({
    super.key,
    required this.project,
  });

  final ProjectModel project;

  /// Helper to display this export configuration sheet.
  static Future<String?> show(BuildContext context, ProjectModel project) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ExportDialog(project: project),
    );
  }

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  late ExportConfig _config;

  @override
  void initState() {
    super.initState();
    _config = const ExportConfig();
  }

  Size get _canvasSize =>
      Size(widget.project.canvasWidth, widget.project.canvasHeight);

  void _setResolution(ExportResolution resolution) {
    setState(() => _config = _config.copyWith(resolution: resolution));
  }

  Future<void> _handleExport() async {
    final saved = await ref
        .read(exportProvider.notifier)
        .exportProject(project: widget.project, config: _config);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(exportProvider).error ?? 'Export failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF14141E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        border: Border(
          top: BorderSide(color: Color(0xFF2E2E40), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12.0),
          Container(
            width: 40.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          const SizedBox(height: 12.0),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export Canvas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '${_config.outputSize(_canvasSize).width.round()} x ${_config.outputSize(_canvasSize).height.round()} px',
                      style: const TextStyle(
                        color: Color(0xFF4E95FF),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2E2E40), height: 16.0),

          // Scrollable Settings
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Format Selection
                  const Text(
                    'File Format',
                    style: TextStyle(color: Colors.white70, fontSize: 13.0, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      _buildFormatChip(
                        key: 'format_png',
                        title: 'PNG (Lossless)',
                        isSelected: _config.format == ExportFormat.png,
                        onTap: () => setState(() => _config = _config.copyWith(format: ExportFormat.png)),
                      ),
                      const SizedBox(width: 10.0),
                      _buildFormatChip(
                        key: 'format_jpeg',
                        title: 'JPEG (Compressed)',
                        isSelected: _config.format == ExportFormat.jpeg,
                        onTap: () => setState(() => _config = _config.copyWith(format: ExportFormat.jpeg)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // JPEG Quality Slider
                  if (_config.format == ExportFormat.jpeg) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'JPEG Quality',
                          style: TextStyle(color: Colors.white70, fontSize: 13.0),
                        ),
                        Text(
                          '${_config.jpegQuality}%',
                          style: const TextStyle(
                            color: Color(0xFF4E95FF),
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      key: const ValueKey('jpeg_quality_slider'),
                      value: _config.jpegQuality.toDouble(),
                      min: 10.0,
                      max: 100.0,
                      divisions: 18,
                      activeColor: const Color(0xFF4E95FF),
                      onChanged: (val) => setState(
                        () => _config = _config.copyWith(jpegQuality: val.round()),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                  ],

                  // Resolution Multipliers
                  const Text(
                    'Export Resolution',
                    style: TextStyle(color: Colors.white70, fontSize: 13.0, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      for (final resolution in ExportResolution.values) ...[
                        if (resolution != ExportResolution.values.first)
                          const SizedBox(width: 8.0),
                        _buildResolutionChip(
                          key: 'res_${resolution.name}',
                          label: resolution.label,
                          isSelected: _config.resolution == resolution,
                          onTap: () => _setResolution(resolution),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  // Watermark Config View
                  WatermarkConfigView(
                    config: _config.watermark,
                    onChanged: (wm) => setState(() => _config = _config.copyWith(watermark: wm)),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton.icon(
                key: const ValueKey('confirm_export_button'),
                onPressed: exportState.isExporting ? null : _handleExport,
                icon: exportState.isExporting
                    ? const SizedBox(
                        width: 18.0,
                        height: 18.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                      )
                    : const Icon(Icons.file_download_outlined),
                label: Text(
                  exportState.isExporting ? 'Rendering Headless Canvas...' : 'Export & Save to Gallery',
                  style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4E95FF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF222230),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip({
    required String key,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        key: ValueKey(key),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4E95FF).withAlpha(40) : const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: isSelected ? const Color(0xFF4E95FF) : const Color(0xFF2E2E40),
              width: 1.5,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF4E95FF) : Colors.white70,
              fontSize: 12.0,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResolutionChip({
    required String key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        key: ValueKey(key),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4E95FF).withAlpha(40) : const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isSelected ? const Color(0xFF4E95FF) : const Color(0xFF2E2E40),
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF4E95FF) : Colors.white70,
              fontSize: 11.0,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
