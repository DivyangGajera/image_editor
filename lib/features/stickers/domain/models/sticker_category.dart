import 'package:flutter/foundation.dart';
import 'sticker_item.dart';

/// Domain entity grouping stickers under a distinct promotional category.
@immutable
class StickerCategory {
  const StickerCategory({
    required this.name,
    required this.stickers,
  });

  /// Name of the category (e.g. 'Discounts', 'Urgency', 'Badges').
  final String name;

  /// Ordered list of sticker items belonging to this category.
  final List<StickerItem> stickers;

  StickerCategory copyWith({
    String? name,
    List<StickerItem>? stickers,
  }) {
    return StickerCategory(
      name: name ?? this.name,
      stickers: stickers ?? this.stickers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StickerCategory &&
        other.name == name &&
        listEquals(other.stickers, stickers);
  }

  @override
  int get hashCode => Object.hash(name, Object.hashAll(stickers));

  @override
  String toString() =>
      'StickerCategory(name: $name, count: ${stickers.length})';
}
