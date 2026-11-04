// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FontEntryAdapter extends TypeAdapter<FontEntry> {
  @override
  final typeId = 5;

  @override
  FontEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FontEntry(
      id: fields[0] as String,
      family: fields[1] as String,
      displayName: fields[2] as String,
      isImported: fields[3] as bool,
      relativePath: fields[4] as String,
      sizeBytes: (fields[5] as num).toInt(),
      addedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FontEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.family)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.isImported)
      ..writeByte(4)
      ..write(obj.relativePath)
      ..writeByte(5)
      ..write(obj.sizeBytes)
      ..writeByte(6)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
