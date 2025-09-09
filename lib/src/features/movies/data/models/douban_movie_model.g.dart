// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'douban_movie_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DoubanMovieModelImpl _$$DoubanMovieModelImplFromJson(
        Map<String, dynamic> json) =>
    _$DoubanMovieModelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      pic: json['poster'] as String?,
      year: json['year'] as String?,
      rateString: json['rate'] as String?,
      url: json['url'] as String?,
      genres:
          (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
      directors: (json['directors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      casts:
          (json['casts'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$DoubanMovieModelImplToJson(
        _$DoubanMovieModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'poster': instance.pic,
      'year': instance.year,
      'rate': instance.rateString,
      'url': instance.url,
      'genres': instance.genres,
      'directors': instance.directors,
      'casts': instance.casts,
    };
