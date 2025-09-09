import 'package:mtv_app/src/features/movies/domain/entities/video_detail.dart';

class VideoDetailModel extends VideoDetail {
  const VideoDetailModel({
    required super.id,
    required super.title,
    required super.poster,
    required super.source,
    required super.sourceName,
    super.desc,
    super.type,
    super.year,
    super.area,
    super.director,
    super.actor,
    super.remarks,
    super.episodes,
  });

  factory VideoDetailModel.fromJson(Map<String, dynamic> json) {
    return VideoDetailModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      poster: json['poster']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      sourceName: json['source_name']?.toString() ?? '',
      desc: json['desc']?.toString(),
      type: json['type']?.toString(),
      year: json['year']?.toString(),
      area: json['area']?.toString(),
      director: json['director']?.toString(),
      actor: json['actor']?.toString(),
      remarks: json['remarks']?.toString(),
      episodes: json['episodes'] != null ? List<String>.from(json['episodes']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster': poster,
      'source': source,
      'source_name': sourceName,
      'desc': desc,
      'type': type,
      'year': year,
      'area': area,
      'director': director,
      'actor': actor,
      'remarks': remarks,
      'episodes': episodes,
    };
  }
}