// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayRecordModelImpl _$$PlayRecordModelImplFromJson(
        Map<String, dynamic> json) =>
    _$PlayRecordModelImpl(
      title: json['title'] as String? ?? '',
      sourceName: json['source_name'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      index: (json['index'] as num?)?.toInt() ?? 0,
      totalEpisodes: (json['total_episodes'] as num?)?.toInt() ?? 0,
      playTime: (json['play_time'] as num?)?.toInt() ?? 0,
      totalTime: (json['total_time'] as num?)?.toInt() ?? 0,
      saveTime: (json['save_time'] as num?)?.toInt() ?? 0,
      year: json['year'] as String? ?? '',
      searchTitle: json['search_title'] as String?,
    );

Map<String, dynamic> _$$PlayRecordModelImplToJson(
        _$PlayRecordModelImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'source_name': instance.sourceName,
      'cover': instance.cover,
      'index': instance.index,
      'total_episodes': instance.totalEpisodes,
      'play_time': instance.playTime,
      'total_time': instance.totalTime,
      'save_time': instance.saveTime,
      'year': instance.year,
      'search_title': instance.searchTitle,
    };
