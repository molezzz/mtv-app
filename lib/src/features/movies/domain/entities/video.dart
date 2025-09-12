import 'package:equatable/equatable.dart';

class Video extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? pic; // 海报图片
  final String? year; // 年份
  final String? note; // 备注信息
  final String? type; // 类型
  final String? source; // 视频源
  final String? sourceName; // 视频源名称
  final String? quality; // 分辨率标签，如 "4K", "1080p", "720p" 等

  const Video({
    required this.id,
    required this.title,
    this.description,
    this.pic,
    this.year,
    this.note,
    this.type,
    this.source,
    this.sourceName,
    this.quality,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        pic,
        year,
        note,
        type,
        source,
        sourceName,
        quality
      ];
}
