// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CanvasSnapshotAdapter extends TypeAdapter<CanvasSnapshot> {
  @override
  final typeId = 7;

  @override
  CanvasSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CanvasSnapshot(
      layers: (fields[0] as List).cast<CanvasLayer>(),
      backgroundColorValue: fields[1] == null
          ? CanvasSnapshot.defaultBackgroundColor
          : (fields[1] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, CanvasSnapshot obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.layers)
      ..writeByte(1)
      ..write(obj.backgroundColorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
