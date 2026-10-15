import 'package:flutter/material.dart';
import 'package:image_editor/core/utils/color_filters.dart';

/// Horizontal selector bar allowing instant switching between GPU-accelerated color filters.
class FilterSelectorBar extends StatelessWidget {
  const FilterSelectorBar({
    super.key,
    required this.selectedFilterId,
    required this.onFilterSelected,
  });

  /// Currently active filter identifier (e.g. 'none', 'grayscale', 'warm', etc.).
  final String? selectedFilterId;

  /// Callback executed when a filter is chosen.
  final ValueChanged<String?> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final activeId = selectedFilterId ?? 'none';

    return SizedBox(
      height: 44.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: AppColorFilters.availableFilters.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final filter = AppColorFilters.availableFilters[index];
          final isSelected = filter.id.toLowerCase() == activeId.toLowerCase();

          return ChoiceChip(
            key: ValueKey('filter_chip_${filter.id}'),
            label: Text(
              filter.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            selectedColor: const Color(0xFF4E95FF),
            backgroundColor: const Color(0xFF1E1E2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
              side: BorderSide(
                color: isSelected ? const Color(0xFF4E95FF) : const Color(0xFF2E2E40),
                width: 1.0,
              ),
            ),
            showCheckmark: false,
            onSelected: (_) {
              onFilterSelected(filter.id == 'none' ? null : filter.id);
            },
          );
        },
      ),
    );
  }
}
