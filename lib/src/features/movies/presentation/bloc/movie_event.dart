import 'package:equatable/equatable.dart';

abstract class MovieEvent extends Equatable {
  const MovieEvent();

  @override
  List<Object> get props => [];
}

class FetchPopularMovies extends MovieEvent {}

class FetchDoubanMovies extends MovieEvent {
  final String type;
  final String tag;
  final int pageSize;
  final int pageStart;

  const FetchDoubanMovies({
    required this.type,
    required this.tag,
    this.pageSize = 20,
    this.pageStart = 0,
  });

  @override
  List<Object> get props => [type, tag, pageSize, pageStart];
}

class FetchDoubanCategories extends MovieEvent {
  final String kind;
  final String category;
  final String type;
  final int limit;
  final int start;

  const FetchDoubanCategories({
    required this.kind,
    required this.category,
    required this.type,
    this.limit = 25,
    this.start = 0,
  });

  @override
  List<Object> get props => [kind, category, type, limit, start];
}

class SearchVideosEvent extends MovieEvent {
  final String query;

  const SearchVideosEvent(this.query);

  @override
  List<Object> get props => [query];
}

class FetchVideoSources extends MovieEvent {}

class SelectCategory extends MovieEvent {
  final String category;
  final String type;

  const SelectCategory({
    required this.category,
    required this.type,
  });

  @override
  List<Object> get props => [category, type];
}

class FetchVideoDetail extends MovieEvent {
  final String source;
  final String id;

  const FetchVideoDetail({
    required this.source,
    required this.id,
  });

  @override
  List<Object> get props => [source, id];
}

class GetVideoDetailEvent extends MovieEvent {
  final String source;
  final String id;

  const GetVideoDetailEvent(this.source, this.id);

  @override
  List<Object> get props => [source, id];
}

class FetchMoreDoubanMovies extends MovieEvent {
  final String type;
  final String tag;
  final int pageStart;

  const FetchMoreDoubanMovies({
    required this.type,
    required this.tag,
    required this.pageStart,
  });

  @override
  List<Object> get props => [type, tag, pageStart];
}

class FetchMoreDoubanCategories extends MovieEvent {
  final String kind;
  final String category;
  final String type;
  final int start;

  const FetchMoreDoubanCategories({
    required this.kind,
    required this.category,
    required this.type,
    required this.start,
  });

  @override
  List<Object> get props => [kind, category, type, start];
}
