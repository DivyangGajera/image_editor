// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_layer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TextLayerAdapter extends TypeAdapter<TextLayer> {
  @override
  final typeId = 1;

  @override
  TextLayer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TextLayer(
      id: fields[0] as String,
      x: (fields[1] as num).toDouble(),
      y: (fields[2] as num).toDouble(),
      scale: fields[3] == null ? 1.0 : (fields[3] as num).toDouble(),
      rotation: fields[4] == null ? 0.0 : (fields[4] as num).toDouble(),
      zIndex: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      isVisible: fields[6] == null ? true : fields[6] as bool,
      text: fields[7] as String,
      fontFamily: fields[8] == null ? 'Roboto' : fields[8] as String,
      isCustomFont: fields[9] == null ? false : fields[9] as bool,
      customFontPath: fields[10] as String?,
      textColorValue: fields[11] == null
          ? 0xFFFFFFFF
          : (fields[11] as num).toInt(),
      fontSize: fields[12] == null ? 24.0 : (fields[12] as num).toDouble(),
      isBold: fields[13] == null ? false : fields[13] as bool,
      isItalic: fields[14] == null ? false : fields[14] as bool,
      boxColorValue: (fields[15] as num?)?.toInt(),
      boxBorderRadius: fields[16] == null
          ? 0.0
          : (fields[16] as num).toDouble(),
      shadowColorValue: (fields[17] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, TextLayer obj) {
    writer
      ..writeByte(18)
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
      ..write(obj.text)
      ..writeByte(8)
      ..write(obj.fontFamily)
      ..writeByte(9)
      ..write(obj.isCustomFont)
      ..writeByte(10)
      ..write(obj.customFontPath)
      ..writeByte(11)
      ..write(obj.textColorValue)
      ..writeByte(12)
      ..write(obj.fontSize)
      ..writeByte(13)
      ..write(obj.isBold)
      ..writeByte(14)
      ..write(obj.isItalic)
      ..writeByte(15)
      ..write(obj.boxColorValue)
      ..writeByte(16)
      ..write(obj.boxBorderRadius)
      ..writeByte(17)
      ..write(obj.shadowColorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextLayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
