// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_video_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchVideoModelImpl _$$SearchVideoModelImplFromJson(
        Map<String, dynamic> json) =>
    _$SearchVideoModelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      poster: json['poster'] as String?,
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      source: json['source'] as String?,
      sourceName: json['source_name'] as String?,
      category: json['class'] as String?,
      year: json['year'] as String?,
      desc: json['desc'] as String?,
      type: json['type_name'] as String?,
      doubanId: (json['douban_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$SearchVideoModelImplToJson(
        _$SearchVideoModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'poster': instance.poster,
      'episodes': instance.episodes,
      'source': instance.source,
      'source_name': instance.sourceName,
      'class': instance.category,
      'year': instance.year,
      'desc': instance.desc,
      'type_name': instance.type,
      'douban_id': instance.doubanId,
    };
