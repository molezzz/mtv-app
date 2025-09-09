// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoModelImpl _$$VideoModelImplFromJson(Map<String, dynamic> json) =>
    _$VideoModelImpl(
      id: json['vod_id'] as String,
      title: json['vod_name'] as String,
      description: json['vod_content'] as String?,
      pic: json['vod_pic'] as String?,
      year: json['vod_year'] as String?,
      note: json['vod_remarks'] as String?,
      type: json['type_name'] as String?,
      source: json['source'] as String?,
    );

Map<String, dynamic> _$$VideoModelImplToJson(_$VideoModelImpl instance) =>
    <String, dynamic>{
      'vod_id': instance.id,
      'vod_name': instance.title,
      'vod_content': instance.description,
      'vod_pic': instance.pic,
      'vod_year': instance.year,
      'vod_remarks': instance.note,
      'type_name': instance.type,
      'source': instance.source,
    };
