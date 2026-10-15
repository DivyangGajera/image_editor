// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sticker_layer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StickerLayerAdapter extends TypeAdapter<StickerLayer> {
  @override
  final typeId = 3;

  @override
  StickerLayer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StickerLayer(
      id: fields[0] as String,
      x: (fields[1] as num).toDouble(),
      y: (fields[2] as num).toDouble(),
      scale: fields[3] == null ? 1.0 : (fields[3] as num).toDouble(),
      rotation: fields[4] == null ? 0.0 : (fields[4] as num).toDouble(),
      zIndex: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      isVisible: fields[6] == null ? true : fields[6] as bool,
      assetPath: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StickerLayer obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.assetPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StickerLayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
