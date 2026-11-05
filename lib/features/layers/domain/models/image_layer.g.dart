// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_layer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImageLayerAdapter extends TypeAdapter<ImageLayer> {
  @override
  final typeId = 0;

  @override
  ImageLayer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageLayer(
      id: fields[0] as String,
      x: (fields[1] as num).toDouble(),
      y: (fields[2] as num).toDouble(),
      scale: fields[3] == null ? 1.0 : (fields[3] as num).toDouble(),
      rotation: fields[4] == null ? 0.0 : (fields[4] as num).toDouble(),
      zIndex: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      isVisible: fields[6] == null ? true : fields[6] as bool,
      isLocked: fields[30] == null ? false : fields[30] as bool,
      relativeImagePath: fields[7] as String,
      isFlippedHorizontally: fields[8] == null ? false : fields[8] as bool,
      activeFilter: fields[9] as String?,
      originalImagePath: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ImageLayer obj) {
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
      ..write(obj.relativeImagePath)
      ..writeByte(8)
      ..write(obj.isFlippedHorizontally)
      ..writeByte(9)
      ..write(obj.activeFilter)
      ..writeByte(11)
      ..write(obj.originalImagePath)
      ..writeByte(30)
      ..write(obj.isLocked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageLayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
