import 'package:equatable/equatable.dart';
import 'package:mtv_app/src/features/movies/domain/entities/movie.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/features/movies/domain/entities/douban_movie.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video_detail.dart';

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
  final bool hasReachedMax;

  const DoubanMoviesLoaded({
    required this.movies,
    required this.category,
    required this.type,
    this.hasReachedMax = false,
  });

  DoubanMoviesLoaded copyWith({
    List<DoubanMovie>? movies,
    String? category,
    String? type,
    bool? hasReachedMax,
  }) {
    return DoubanMoviesLoaded(
      movies: movies ?? this.movies,
      category: category ?? this.category,
      type: type ?? this.type,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [movies, category, type, hasReachedMax];
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

class VideoDetailLoaded extends MovieState {
  final VideoDetail videoDetail;

  const VideoDetailLoaded({required this.videoDetail});

  @override
  List<Object> get props => [videoDetail];
}

class VideoDetailLoading extends MovieState {}

class MovieError extends MovieState {
  final String message;

  const MovieError({required this.message});

  @override
  List<Object> get props => [message];
}
