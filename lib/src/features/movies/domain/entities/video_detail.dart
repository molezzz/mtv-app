import 'package:equatable/equatable.dart';

class VideoDetail extends Equatable {
  final String id;
  final String title;
  final String poster;
  final String source;
  final String sourceName;
  final String? desc;
  final String? type;
  final String? year;
  final String? area;
  final String? director;
  final String? actor;
  final String? remarks;
  final List<String>? episodes; // 播放源列表

  const VideoDetail({
    required this.id,
    required this.title,
    required this.poster,
    required this.source,
    required this.sourceName,
    this.desc,
    this.type,
    this.year,
    this.area,
    this.director,
    this.actor,
    this.remarks,
    this.episodes,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        poster,
        source,
        sourceName,
        desc,
        type,
        year,
        area,
        director,
        actor,
        remarks,
        episodes,
      ];
}
