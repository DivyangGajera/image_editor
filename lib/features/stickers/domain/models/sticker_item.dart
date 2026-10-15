import 'package:flutter/foundation.dart';

/// Pure domain entity representing a promotional badge or sticker asset.
@immutable
class StickerItem {
  const StickerItem({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.category,
  });

  /// Unique identifier for the sticker (e.g. 'discount_50_off').
  final String id;

  /// Human-readable label (e.g. '50% OFF').
  final String title;

  /// Asset bundle path to the PNG image.
  final String assetPath;

  /// Category name grouping this sticker (e.g. 'Discounts', 'Urgency', 'Badges').
  final String category;

  StickerItem copyWith({
    String? id,
    String? title,
    String? assetPath,
    String? category,
  }) {
    return StickerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      assetPath: assetPath ?? this.assetPath,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StickerItem &&
        other.id == id &&
        other.title == title &&
        other.assetPath == assetPath &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(id, title, assetPath, category);

  @override
  String toString() =>
      'StickerItem(id: $id, title: $title, category: $category, assetPath: $assetPath)';
}
