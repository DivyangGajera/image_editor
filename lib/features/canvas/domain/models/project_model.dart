import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:image_editor/core/constants/app_constants.dart';
import 'package:image_editor/core/storage/storage_keys.dart';
import 'package:image_editor/features/layers/domain/models/models.dart';

part 'project_model.g.dart';

/// Represents an offline image editing project session with canvas properties and layered entities.
@HiveType(typeId: HiveTypeIds.projectModel)
class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.title,
    this.canvasWidth = AppConstants.defaultCanvasWidth,
    this.canvasHeight = AppConstants.defaultCanvasHeight,
    this.layers = const <CanvasLayer>[],
    required this.createdAt,
    required this.updatedAt,
    this.backgroundColorValue = ProjectModel.defaultBackgroundColor,
  });

  /// Canvas background of new projects (and of projects created before the
  /// background was configurable).
  static const int defaultBackgroundColor = 0xFFFFFFFF;

  /// Unique project ID (UUID v4).
  @HiveField(0)
  final String id;

  /// Human-readable project title.
  @HiveField(1)
  final String title;

  /// Width of the editing canvas in logical pixels.
  @HiveField(2)
  final double canvasWidth;

  /// Height of the editing canvas in logical pixels.
  @HiveField(3)
  final double canvasHeight;

  /// Stacking list of active canvas layers.
  @HiveField(4)
  final List<CanvasLayer> layers;

  /// Project creation timestamp.
  @HiveField(5)
  final DateTime createdAt;

  /// Timestamp of the latest project edit.
  @HiveField(6)
  final DateTime updatedAt;

  /// ARGB solid color behind all layers, on screen and in exports.
  @HiveField(7, defaultValue: ProjectModel.defaultBackgroundColor)
  final int backgroundColorValue;

  ProjectModel copyWith({
    String? id,
    String? title,
    double? canvasWidth,
    double? canvasHeight,
    List<CanvasLayer>? layers,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? backgroundColorValue,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      layers: layers ?? List<CanvasLayer>.from(this.layers),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectModel &&
        other.id == id &&
        other.title == title &&
        other.canvasWidth == canvasWidth &&
        other.canvasHeight == canvasHeight &&
        listEquals(other.layers, layers) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.backgroundColorValue == backgroundColorValue;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        canvasWidth,
        canvasHeight,
        Object.hashAll(layers),
        createdAt,
        updatedAt,
        backgroundColorValue,
      );

  @override
  String toString() =>
      'ProjectModel(id: $id, title: $title, canvasWidth: $canvasWidth, '
      'canvasHeight: $canvasHeight, layersCount: ${layers.length}, '
      'createdAt: $createdAt, updatedAt: $updatedAt)';
}
