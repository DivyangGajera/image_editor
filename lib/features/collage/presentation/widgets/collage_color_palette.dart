import 'package:flutter/material.dart';

/// Predefined curated border colors for collage frames.
const List<int> kDefaultCollageColors = [
  0xFFFFFFFF, // Pure White
  0xFF121212, // Dark Obsidian
  0xFFFFF9E6, // Warm Cream
  0xFFFFD700, // Metallic Gold
  0xFF00E5FF, // Cyber Cyan
  0xFFFF4081, // Neon Pink
  0xFF6366F1, // Vibrant Indigo
  0xFF4CAF50, // Fresh Green
];

/// Horizontal palette of circular color swatches for choosing collage border frames.
class CollageColorPalette extends StatelessWidget {
  const CollageColorPalette({
    super.key,
    required this.selectedColorValue,
    required this.onColorSelected,
  });

  final int selectedColorValue;
  final ValueChanged<int> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kDefaultCollageColors.length,
        separatorBuilder: (_, index) => const SizedBox(width: 10.0),
        itemBuilder: (context, index) {
          final colorVal = kDefaultCollageColors[index];
          final isSelected = colorVal == selectedColorValue;
          final color = Color(colorVal);

          return GestureDetector(
            key: ValueKey('collage_color_${colorVal.toRadixString(16)}'),
            onTap: () => onColorSelected(colorVal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4E95FF)
                      : const Color(0xFF3E3E50),
                  width: isSelected ? 3.0 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4E95FF).withAlpha(120),
                          blurRadius: 8.0,
                          spreadRadius: 1.0,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 20.0,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
