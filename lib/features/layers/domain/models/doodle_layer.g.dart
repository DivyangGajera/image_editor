// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doodle_layer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DoodleLayerAdapter extends TypeAdapter<DoodleLayer> {
  @override
  final typeId = 2;

  @override
  DoodleLayer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoodleLayer(
      id: fields[0] as String,
      x: (fields[1] as num).toDouble(),
      y: (fields[2] as num).toDouble(),
      scale: fields[3] == null ? 1.0 : (fields[3] as num).toDouble(),
      rotation: fields[4] == null ? 0.0 : (fields[4] as num).toDouble(),
      zIndex: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      isVisible: fields[6] == null ? true : fields[6] as bool,
      isLocked: fields[30] == null ? false : fields[30] as bool,
      points: (fields[7] as List)
          .map((e) => (e as List).cast<double>())
          .toList(),
      strokeColorValue: fields[8] == null
          ? 0xFFFF0000
          : (fields[8] as num).toInt(),
      strokeWidth: fields[9] == null ? 5.0 : (fields[9] as num).toDouble(),
      hasGlow: fields[10] == null ? false : fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DoodleLayer obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.x)
      ..writeByte(2)
      ..write(obj.y)
      ..writeByte(3)
      ..write(obj.scale)
      ..writeByte(4)
      ..write(obj.rotation)
      ..writeByte(5)
      ..write(obj.zIndex)
      ..writeByte(6)
      ..write(obj.isVisible)
      ..writeByte(7)
      ..write(obj.points)
      ..writeByte(8)
      ..write(obj.strokeColorValue)
      ..writeByte(9)
      ..write(obj.strokeWidth)
      ..writeByte(10)
      ..write(obj.hasGlow)
      ..writeByte(30)
      ..write(obj.isLocked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoodleLayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
