import 'package:flutter/material.dart';
import 'package:image_editor/features/export/domain/models/models.dart';

/// Configuration widget for customizing watermark text, placement, opacity, and typography.
class WatermarkConfigView extends StatelessWidget {
  const WatermarkConfigView({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final WatermarkConfig config;
  final ValueChanged<WatermarkConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFF2E2E40),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.branding_watermark_outlined, size: 18.0, color: Color(0xFF4E95FF)),
                  SizedBox(width: 8.0),
                  Text(
                    'Watermark',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Switch(
                key: const ValueKey('enable_watermark_switch'),
                value: config.isEnabled,
                activeThumbColor: const Color(0xFF4E95FF),
                onChanged: (val) => onChanged(config.copyWith(isEnabled: val)),
              ),
            ],
          ),
          if (config.isEnabled) ...[
            const SizedBox(height: 12.0),
            // Text field for watermark text
            TextField(
              key: const ValueKey('watermark_text_field'),
              controller: TextEditingController(text: config.text)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: config.text.length),
                ),
              style: const TextStyle(color: Colors.white, fontSize: 13.0),
              decoration: InputDecoration(
                labelText: 'Watermark Text',
                labelStyle: const TextStyle(color: Colors.white60, fontSize: 12.0),
                filled: true,
                fillColor: const Color(0xFF161622),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Color(0xFF3E3E50)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Color(0xFF4E95FF)),
                ),
              ),
              onChanged: (val) => onChanged(config.copyWith(text: val)),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'Position',
              style: TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: [
                _buildPositionChip(
                  key: 'watermark_pos_bottomRight',
                  label: 'Bottom-Right',
                  isSelected: config.position == WatermarkPosition.bottomRight,
                  onTap: () => onChanged(config.copyWith(position: WatermarkPosition.bottomRight)),
                ),
                _buildPositionChip(
                  key: 'watermark_pos_bottomLeft',
                  label: 'Bottom-Left',
                  isSelected: config.position == WatermarkPosition.bottomLeft,
                  onTap: () => onChanged(config.copyWith(position: WatermarkPosition.bottomLeft)),
                ),
                _buildPositionChip(
                  key: 'watermark_pos_center',
                  label: 'Center',
                  isSelected: config.position == WatermarkPosition.center,
                  onTap: () => onChanged(config.copyWith(position: WatermarkPosition.center)),
                ),
                _buildPositionChip(
                  key: 'watermark_pos_tiled',
                  label: 'Tiled Pattern',
                  isSelected: config.position == WatermarkPosition.tiled,
                  onTap: () => onChanged(config.copyWith(position: WatermarkPosition.tiled)),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            // Opacity slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Opacity',
                  style: TextStyle(color: Colors.white70, fontSize: 12.0),
                ),
                Text(
                  '${(config.opacity * 100).toInt()}%',
                  style: const TextStyle(color: Color(0xFF4E95FF), fontSize: 12.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF4E95FF),
                inactiveTrackColor: const Color(0xFF2A2A3C),
                thumbColor: Colors.white,
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              ),
              child: Slider(
                key: const ValueKey('watermark_opacity_slider'),
                value: config.opacity,
                min: 0.1,
                max: 1.0,
                divisions: 18,
                onChanged: (val) => onChanged(config.copyWith(opacity: val)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPositionChip({
    required String key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: ValueKey(key),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4E95FF).withAlpha(40) : const Color(0xFF161622),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? const Color(0xFF4E95FF) : const Color(0xFF3E3E50),
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
    );
  }
}
