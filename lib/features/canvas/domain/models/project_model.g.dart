// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectModelAdapter extends TypeAdapter<ProjectModel> {
  @override
  final typeId = 4;

  @override
  ProjectModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectModel(
      id: fields[0] as String,
      title: fields[1] as String,
      canvasWidth: fields[2] == null
          ? AppConstants.defaultCanvasWidth
          : (fields[2] as num).toDouble(),
      canvasHeight: fields[3] == null
          ? AppConstants.defaultCanvasHeight
          : (fields[3] as num).toDouble(),
      layers: fields[4] == null
          ? const <CanvasLayer>[]
          : (fields[4] as List).cast<CanvasLayer>(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      backgroundColorValue: fields[7] == null
          ? 4294967295
          : (fields[7] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ProjectModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.canvasWidth)
      ..writeByte(3)
      ..write(obj.canvasHeight)
      ..writeByte(4)
      ..write(obj.layers)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.backgroundColorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
