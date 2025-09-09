import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String type; // 'movie' or 'tv'
  final String? tag; // 豆瓣标签，如 "热门", "最新", "top250"

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.tag,
  });

  @override
  List<Object?> get props => [id, name, type, tag];
}