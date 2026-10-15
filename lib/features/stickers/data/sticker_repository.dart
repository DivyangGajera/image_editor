import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_editor/features/stickers/domain/models/models.dart';

/// Repository providing a categorized manifest of bundled promotional badge
/// and sticker assets.
class StickerRepository {
  const StickerRepository();

  static const List<StickerItem> _discountStickers = <StickerItem>[
    StickerItem(
      id: 'discount_50_off',
      title: '50% OFF',
      assetPath: 'assets/stickers/discounts/discount_50_off.png',
      category: 'Discounts',
    ),
    StickerItem(
      id: 'discount_bogo',
      title: 'BUY 1 GET 1',
      assetPath: 'assets/stickers/discounts/discount_bogo.png',
      category: 'Discounts',
    ),
    StickerItem(
      id: 'discount_special_offer',
      title: 'SPECIAL OFFER',
      assetPath: 'assets/stickers/discounts/discount_special_offer.png',
      category: 'Discounts',
    ),
  ];

  static const List<StickerItem> _urgencyStickers = <StickerItem>[
    StickerItem(
      id: 'urgency_limited_time',
      title: 'LIMITED TIME',
      assetPath: 'assets/stickers/urgency/urgency_limited_time.png',
      category: 'Urgency',
    ),
    StickerItem(
      id: 'urgency_sale_ends_today',
      title: 'SALE ENDS TODAY',
      assetPath: 'assets/stickers/urgency/urgency_sale_ends_today.png',
      category: 'Urgency',
    ),
    StickerItem(
      id: 'urgency_last_chance',
      title: 'LAST CHANCE',
      assetPath: 'assets/stickers/urgency/urgency_last_chance.png',
      category: 'Urgency',
    ),
  ];

  static const List<StickerItem> _badgeStickers = <StickerItem>[
    StickerItem(
      id: 'badge_bestseller',
      title: 'BESTSELLER',
      assetPath: 'assets/stickers/badges/badge_bestseller.png',
      category: 'Badges',
    ),
    StickerItem(
      id: 'badge_new_arrival',
      title: 'NEW ARRIVAL',
      assetPath: 'assets/stickers/badges/badge_new_arrival.png',
      category: 'Badges',
    ),
    StickerItem(
      id: 'badge_premium_quality',
      title: 'PREMIUM QUALITY',
      assetPath: 'assets/stickers/badges/badge_premium_quality.png',
      category: 'Badges',
    ),
  ];

  /// Retrieves all categorized sticker groupings.
  List<StickerCategory> getCategories() {
    return const <StickerCategory>[
      StickerCategory(name: 'Discounts', stickers: _discountStickers),
      StickerCategory(name: 'Urgency', stickers: _urgencyStickers),
      StickerCategory(name: 'Badges', stickers: _badgeStickers),
    ];
  }

  /// Retrieves a flattened list of all available sticker assets.
  List<StickerItem> getAllStickers() {
    return const <StickerItem>[
      ..._discountStickers,
      ..._urgencyStickers,
      ..._badgeStickers,
    ];
  }

  /// Retrieves stickers filtered by [category].
  List<StickerItem> getStickersByCategory(String category) {
    return getAllStickers().where((s) => s.category.toLowerCase() == category.toLowerCase()).toList();
  }
}

/// Riverpod provider for singleton instance of [StickerRepository].
final stickerRepositoryProvider = Provider<StickerRepository>((ref) {
  return const StickerRepository();
});
