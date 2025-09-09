import 'package:equatable/equatable.dart';
import 'package:mtv_app/src/features/movies/domain/entities/movie.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/features/movies/domain/entities/douban_movie.dart';

abstract class MovieState extends Equatable {
  const MovieState();

  @override
  List<Object> get props => [];
}

class MovieInitial extends MovieState {}

class MovieLoading extends MovieState {}

class MovieLoaded extends MovieState {
  final List<Movie> movies;

  const MovieLoaded({required this.movies});

  @override
  List<Object> get props => [movies];
}

class DoubanMoviesLoaded extends MovieState {
  final List<DoubanMovie> movies;
  final String category;
  final String type;

  const DoubanMoviesLoaded({
    required this.movies,
    required this.category,
    required this.type,
  });

  @override
  List<Object> get props => [movies, category, type];
}

class VideosLoaded extends MovieState {
  final List<Video> videos;
  final String query;

  const VideosLoaded({
    required this.videos,
    required this.query,
  });

  @override
  List<Object> get props => [videos, query];
}

class VideoSourcesLoaded extends MovieState {
  final List<Map<String, dynamic>> sources;

  const VideoSourcesLoaded({required this.sources});

  @override
  List<Object> get props => [sources];
}

class MovieError extends MovieState {
  final String message;

  const MovieError({required this.message});

  @override
  List<Object> get props => [message];
}
