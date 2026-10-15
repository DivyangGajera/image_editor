import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/core/utils/color_filters.dart';

void main() {
  group('AppColorFilters', () {
    test('all filter matrices contain exactly 20 elements', () {
      for (final filter in AppColorFilters.availableFilters) {
        expect(filter.matrix.length, equals(20),
            reason: '${filter.id} matrix must have 20 elements');
      }
    });

    test('identity matrix preserves RGBA channels unchanged', () {
      const identity = AppColorFilters.identityMatrix;
      expect(identity[0], equals(1.0)); // R -> R
      expect(identity[6], equals(1.0)); // G -> G
      expect(identity[12], equals(1.0)); // B -> B
      expect(identity[18], equals(1.0)); // A -> A

      // Check zero offsets
      expect(identity[4], equals(0.0));
      expect(identity[9], equals(0.0));
      expect(identity[14], equals(0.0));
      expect(identity[19], equals(0.0));
    });

    test('grayscale luminance weights sum to 1.0', () {
      const grayscale = AppColorFilters.grayscaleMatrix;
      final sum = grayscale[0] + grayscale[1] + grayscale[2];
      expect(sum, closeTo(1.0, 0.0001));
      expect(grayscale[18], equals(1.0)); // Alpha preservation
    });

    test('getFilterByName retrieves valid ColorFilters', () {
      expect(AppColorFilters.getFilterByName('none'), isNull);
      expect(AppColorFilters.getFilterByName(null), isNull);
      expect(AppColorFilters.getFilterByName('unknown'), isNull);

      final gray = AppColorFilters.getFilterByName('grayscale');
      expect(gray, isNotNull);
      expect(gray, isA<ColorFilter>());

      final warm = AppColorFilters.getFilterByName('WARM');
      expect(warm, isNotNull);

      final cool = AppColorFilters.getFilterByName('Cool');
      expect(cool, isNotNull);

      final contrast = AppColorFilters.getFilterByName('high_contrast');
      expect(contrast, isNotNull);
    });

    test('getFilterItemById resolves expected filter item or defaults to none', () {
      final item = AppColorFilters.getFilterItemById('warm');
      expect(item.id, equals('warm'));
      expect(item.name, equals('Warm'));

      final defaultItem = AppColorFilters.getFilterItemById(null);
      expect(defaultItem.id, equals('none'));

      final fallbackItem = AppColorFilters.getFilterItemById('non_existent');
      expect(fallbackItem.id, equals('none'));
    });
  });
}
