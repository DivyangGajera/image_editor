// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_sticker.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserStickerAdapter extends TypeAdapter<UserSticker> {
  @override
  final typeId = 6;

  @override
  UserSticker read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSticker(
      id: fields[0] as String,
      relativePath: fields[1] as String,
      width: (fields[2] as num).toInt(),
      height: (fields[3] as num).toInt(),
      addedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserSticker obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.relativePath)
      ..writeByte(2)
      ..write(obj.width)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStickerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
