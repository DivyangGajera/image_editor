import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

part 'canvas_snapshot.g.dart';

/// Everything one undo step restores: the layers and the canvas background.
@immutable
@HiveType(typeId: HiveTypeIds.canvasSnapshot)
class CanvasSnapshot {
  const CanvasSnapshot({
    required this.layers,
    this.backgroundColorValue = CanvasSnapshot.defaultBackgroundColor,
  });

  /// Background of projects created before backgrounds were configurable.
  static const int defaultBackgroundColor = 0xFFFFFFFF;

  @HiveField(0)
  final List<CanvasLayer> layers;

  /// ARGB canvas background color.
  @HiveField(1)
  final int backgroundColorValue;

  /// A copy whose layers are independent of this snapshot's.
  CanvasSnapshot clone() => CanvasSnapshot(
        layers: layers.map((layer) => layer.copyWith()).toList(),
        backgroundColorValue: backgroundColorValue,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasSnapshot &&
          other.backgroundColorValue == backgroundColorValue &&
          listEquals(other.layers, layers);

  @override
  int get hashCode => Object.hash(Object.hashAll(layers), backgroundColorValue);
}
