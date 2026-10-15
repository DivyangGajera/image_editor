import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_editor/features/stickers/data/sticker_repository.dart';

void main() {
  group('StickerRepository', () {
    late StickerRepository repository;

    setUp(() {
      repository = const StickerRepository();
    });

    test('getCategories returns 3 distinct categories with expected names', () {
      final categories = repository.getCategories();
      expect(categories.length, equals(3));
      expect(categories.map((c) => c.name).toList(), equals(['Discounts', 'Urgency', 'Badges']));
    });

    test('each category contains valid StickerItem records', () {
      final categories = repository.getCategories();
      for (final cat in categories) {
        expect(cat.stickers, isNotEmpty);
        for (final item in cat.stickers) {
          expect(item.id, isNotEmpty);
          expect(item.title, isNotEmpty);
          expect(item.assetPath, startsWith('assets/stickers/'));
          expect(item.assetPath, endsWith('.png'));
          expect(item.category, equals(cat.name));
        }
      }
    });

    test('getAllStickers returns all bundled items', () {
      final all = repository.getAllStickers();
      expect(all.length, equals(9));
      expect(all.map((s) => s.id).toSet().length, equals(9), reason: 'IDs must be unique');
    });

    test('getStickersByCategory filters correctly with case-insensitivity', () {
      final discounts = repository.getStickersByCategory('discounts');
      expect(discounts.length, equals(3));
      for (final item in discounts) {
        expect(item.category, equals('Discounts'));
      }

      final urgency = repository.getStickersByCategory('URGENCY');
      expect(urgency.length, equals(3));

      final unknown = repository.getStickersByCategory('non_existent');
      expect(unknown, isEmpty);
    });

    test('stickerRepositoryProvider provides singleton StickerRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = container.read(stickerRepositoryProvider);
      final repo2 = container.read(stickerRepositoryProvider);

      expect(repo1, isA<StickerRepository>());
      expect(identical(repo1, repo2), isTrue);
    });
  });
}
