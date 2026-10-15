import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/canvas/domain/models/project_model.dart';
import 'package:image_editor/features/collage/application/collage_engine.dart';
import 'package:image_editor/features/collage/application/collage_notifier.dart';
import 'package:image_editor/features/collage/domain/models/models.dart';
import 'package:image_editor/features/collage/presentation/widgets/collage_color_palette.dart';
import 'package:image_editor/features/collage/presentation/widgets/collage_preview_box.dart';
import 'package:image_picker/image_picker.dart';

/// Dedicated screen for composing collages and filmstrips from 2 to 9 images.
class CollageSetupScreen extends ConsumerStatefulWidget {
  const CollageSetupScreen({
    super.key,
    this.imagePicker,
    this.onProjectCreated,
  });

  /// Optional injected [ImagePicker] for testability.
  final ImagePicker? imagePicker;

  /// Optional callback invoked when a project is generated.
  final ValueChanged<ProjectModel>? onProjectCreated;

  @override
  ConsumerState<CollageSetupScreen> createState() => _CollageSetupScreenState();
}

class _CollageSetupScreenState extends ConsumerState<CollageSetupScreen> {
  late final ImagePicker _picker;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(limit: 9);
      if (picked.isNotEmpty && mounted) {
        final paths = picked.map((x) => x.path).toList();
        ref.read(collageNotifierProvider.notifier).addImages(paths);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select photos: $e')),
        );
      }
    }
  }

  Future<void> _handleCreateProject() async {
    try {
      final project = await ref
          .read(collageNotifierProvider.notifier)
          .createProject();

      if (project != null && mounted) {
        if (widget.onProjectCreated != null) {
          widget.onProjectCreated!(project);
        } else {
          Navigator.of(context).pop(project);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create collage: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(collageNotifierProvider);
    final notifier = ref.read(collageNotifierProvider.notifier);
    final engine = ref.watch(collageEngineProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF101018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161622),
        title: const Text(
          'Collage & Filmstrip',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              key: const ValueKey('create_collage_project_button'),
              onPressed: state.canCreate ? _handleCreateProject : null,
              icon: state.isCreating
                  ? const SizedBox(
                      width: 16.0,
                      height: 16.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 18.0),
              label: const Text('Create'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4E95FF),
                disabledForegroundColor: Colors.white24,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Selection Strip
            _buildSelectionHeader(state),
            const SizedBox(height: 12.0),
            _buildThumbnailStrip(state, notifier),
            const SizedBox(height: 20.0),

            // Live Preview Card
            CollagePreviewBox(
              imagePaths: state.selectedImagePaths,
              config: state.config,
              engine: engine,
            ),
            const SizedBox(height: 24.0),

            // Layout Preset Switcher
            _buildSectionTitle('Layout Preset'),
            const SizedBox(height: 10.0),
            _buildPresetSelector(state, notifier),
            const SizedBox(height: 24.0),

            // Border & Margin Sliders
            _buildSectionTitle('Frame & Spacing'),
            const SizedBox(height: 12.0),
            _buildBorderControls(state, notifier),
            const SizedBox(height: 32.0),

            // Bottom CTA
            SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton.icon(
                key: const ValueKey('bottom_create_project_button'),
                onPressed: state.canCreate ? _handleCreateProject : null,
                icon: state.isCreating
                    ? const SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.brush),
                label: Text(
                  state.isCreating
                      ? 'Building Collage Layers...'
                      : 'Open in Canvas Editor',
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4E95FF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF222230),
                  disabledForegroundColor: Colors.white24,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHeader(CollageState state) {
    final count = state.selectedImagePaths.length;
    final bool isCountValid = count >= 2 && count <= 9;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Photos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: isCountValid
                ? const Color(0xFF4E95FF).withAlpha(40)
                : const Color(0xFFFF4081).withAlpha(40),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isCountValid
                  ? const Color(0xFF4E95FF)
                  : const Color(0xFFFF4081),
              width: 1.0,
            ),
          ),
          child: Text(
            '$count / 9 (Min 2)',
            style: TextStyle(
              color: isCountValid
                  ? const Color(0xFF4E95FF)
                  : const Color(0xFFFF4081),
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailStrip(CollageState state, CollageNotifier notifier) {
    return SizedBox(
      height: 80.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.selectedImagePaths.length + 1,
        separatorBuilder: (_, index) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Add photos tile
            return InkWell(
              key: const ValueKey('add_photos_button'),
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(10.0),
              child: Container(
                width: 72.0,
                height: 80.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: const Color(0xFF3E3E50),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFF4E95FF),
                      size: 26.0,
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final imageIndex = index - 1;
          final path = state.selectedImagePaths[imageIndex];

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72.0,
                height: 80.0,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: const Color(0xFF2E2E40),
                    width: 1.0,
                  ),
                ),
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) => Container(
                    color: const Color(0xFF2A2A3C),
                    child: const Icon(Icons.broken_image, size: 20.0),
                  ),
                ),
              ),
              Positioned(
                top: -4.0,
                right: -4.0,
                child: GestureDetector(
                  key: ValueKey('remove_image_$imageIndex'),
                  onTap: () => notifier.removeImage(imageIndex),
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4081),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetSelector(CollageState state, CollageNotifier notifier) {
    return Row(
      children: [
        _buildPresetTile(
          key: 'preset_grid',
          title: 'Grid Matrix',
          icon: Icons.grid_view_rounded,
          isSelected: state.config.layoutType == CollageLayoutType.gridMatrix,
          onTap: () => notifier.setLayoutType(CollageLayoutType.gridMatrix),
        ),
        const SizedBox(width: 8.0),
        _buildPresetTile(
          key: 'preset_horizontal',
          title: 'Horizontal',
          icon: Icons.view_column_rounded,
          isSelected:
              state.config.layoutType == CollageLayoutType.horizontalStrip,
          onTap: () => notifier.setLayoutType(CollageLayoutType.horizontalStrip),
        ),
        const SizedBox(width: 8.0),
        _buildPresetTile(
          key: 'preset_vertical',
          title: 'Vertical Strip',
          icon: Icons.view_agenda_rounded,
          isSelected:
              state.config.layoutType == CollageLayoutType.verticalStrip,
          onTap: () => notifier.setLayoutType(CollageLayoutType.verticalStrip),
        ),
      ],
    );
  }

  Widget _buildPresetTile({
    required String key,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        key: ValueKey(key),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4E95FF).withAlpha(40)
                : const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4E95FF)
                  : const Color(0xFF2E2E40),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20.0,
                color: isSelected ? const Color(0xFF4E95FF) : Colors.white70,
              ),
              const SizedBox(height: 4.0),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 11.0,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBorderControls(CollageState state, CollageNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFF2E2E40),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Border Width
          _buildSliderRow(
            sliderKey: 'border_width_slider',
            title: 'Border Width',
            valueText: '${state.config.borderWidth.round()} px',
            value: state.config.borderWidth,
            min: 0.0,
            max: 30.0,
            divisions: 30,
            onChanged: (val) => notifier.setBorderWidth(val),
          ),
          const SizedBox(height: 12.0),

          // Border Color Palette
          const Text(
            'Border Color',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8.0),
          CollageColorPalette(
            selectedColorValue: state.config.borderColorValue,
            onColorSelected: (val) => notifier.setBorderColor(val),
          ),
          const Divider(color: Color(0xFF2E2E40), height: 28.0),

          // Cell Spacing
          _buildSliderRow(
            sliderKey: 'spacing_slider',
            title: 'Inner Spacing',
            valueText: '${state.config.spacing.round()} px',
            value: state.config.spacing,
            min: 0.0,
            max: 50.0,
            divisions: 50,
            onChanged: (val) => notifier.setSpacing(val),
          ),
          const SizedBox(height: 12.0),

          // Outer Margin
          _buildSliderRow(
            sliderKey: 'outer_margin_slider',
            title: 'Outer Margin',
            valueText: '${state.config.outerMargin.round()} px',
            value: state.config.outerMargin,
            min: 0.0,
            max: 60.0,
            divisions: 60,
            onChanged: (val) => notifier.setOuterMargin(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String sliderKey,
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                color: Color(0xFF4E95FF),
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF4E95FF),
            inactiveTrackColor: const Color(0xFF2A2A3C),
            thumbColor: Colors.white,
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
          ),
          child: Slider(
            key: ValueKey(sliderKey),
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
