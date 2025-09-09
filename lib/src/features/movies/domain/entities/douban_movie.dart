import 'package:equatable/equatable.dart';

class DoubanMovie extends Equatable {
  final String id;
  final String title;
  final String? pic;
  final String? year;
  final double? rating; // 评分
  final String? url; // 豆瓣链接
  final List<String>? genres; // 类型
  final List<String>? directors; // 导演
  final List<String>? casts; // 演员

  const DoubanMovie({
    required this.id,
    required this.title,
    this.pic,
    this.year,
    this.rating,
    this.url,
    this.genres,
    this.directors,
    this.casts,
  });

  @override
  List<Object?> get props => [id, title, pic, year, rating, url, genres, directors, casts];
}