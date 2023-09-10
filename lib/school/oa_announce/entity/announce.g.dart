// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announce.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnnounceCatalogueAdapter extends TypeAdapter<AnnounceCatalogue> {
  @override
  final int typeId = 92;

  @override
  AnnounceCatalogue read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnounceCatalogue(
      name: fields[0] as String,
      id: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AnnounceCatalogue obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnounceCatalogueAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class AnnounceRecordAdapter extends TypeAdapter<AnnounceRecord> {
  @override
  final int typeId = 94;

  @override
  AnnounceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnounceRecord(
      title: fields[0] as String,
      uuid: fields[1] as String,
      bulletinCatalogueId: fields[2] as String,
      dateTime: fields[3] as DateTime,
      departments: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, AnnounceRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.uuid)
      ..writeByte(2)
      ..write(obj.bulletinCatalogueId)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.departments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnounceRecordAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class AnnounceDetailAdapter extends TypeAdapter<AnnounceDetail> {
  @override
  final int typeId = 90;

  @override
  AnnounceDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnounceDetail(
      title: fields[0] as String,
      dateTime: fields[1] as DateTime,
      department: fields[2] as String,
      author: fields[3] as String,
      readNumber: fields[4] as int,
      content: fields[5] as String,
      attachments: (fields[6] as List).cast<AnnounceAttachment>(),
    );
  }

  @override
  void write(BinaryWriter writer, AnnounceDetail obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.dateTime)
      ..writeByte(2)
      ..write(obj.department)
      ..writeByte(3)
      ..write(obj.author)
      ..writeByte(4)
      ..write(obj.readNumber)
      ..writeByte(5)
      ..write(obj.content)
      ..writeByte(6)
      ..write(obj.attachments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnounceDetailAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class AnnounceAttachmentAdapter extends TypeAdapter<AnnounceAttachment> {
  @override
  final int typeId = 91;

  @override
  AnnounceAttachment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnnounceAttachment(
      name: fields[0] as String,
      url: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AnnounceAttachment obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.url);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnounceAttachmentAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
