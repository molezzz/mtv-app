import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_popular_movies.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_douban_movies.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/search_videos.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_video_sources.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_video_detail.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_event.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_state.dart';

class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final GetPopularMovies getPopularMovies;
  final GetDoubanMovies getDoubanMovies;
  final SearchVideos searchVideos;
  final GetVideoSources getVideoSources;
  final GetVideoDetail getVideoDetail;

  MovieBloc({
    required this.getPopularMovies,
    required this.getDoubanMovies,
    required this.searchVideos,
    required this.getVideoSources,
    required this.getVideoDetail,
  }) : super(MovieInitial()) {
    on<FetchPopularMovies>(_onFetchPopularMovies);
    on<FetchDoubanMovies>(_onFetchDoubanMovies);
    on<SearchVideosEvent>(_onSearchVideos);
    on<FetchVideoSources>(_onFetchVideoSources);
    on<SelectCategory>(_onSelectCategory);
    on<FetchVideoDetail>(_onFetchVideoDetail);
    on<GetVideoDetailEvent>(_onGetVideoDetailEvent);
  }

  Future<void> _onFetchPopularMovies(
    FetchPopularMovies event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await getPopularMovies();
      emit(MovieLoaded(movies: movies));
    } catch (e) {
      emit(const MovieError(message: 'Failed to fetch movies'));
    }
  }

  Future<void> _onFetchDoubanMovies(
    FetchDoubanMovies event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      print('Fetching douban movies: type=${event.type}, tag=${event.tag}');
      final movies = await getDoubanMovies(
        type: event.type,
        tag: event.tag,
        pageSize: event.pageSize,
        pageStart: event.pageStart,
      );
      print('Received ${movies.length} movies');
      emit(DoubanMoviesLoaded(
        movies: movies,
        category: event.tag,
        type: event.type,
      ));
    } catch (e) {
      print('Error fetching douban movies: $e');
      emit(MovieError(message: 'Failed to fetch douban movies: ${e.toString()}'));
    }
  }

  Future<void> _onSearchVideos(
    SearchVideosEvent event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final videos = await searchVideos(event.query);
      emit(VideosLoaded(
        videos: videos,
        query: event.query,
      ));
    } catch (e) {
      emit(MovieError(message: 'Failed to search videos: ${e.toString()}'));
    }
  }

  Future<void> _onFetchVideoSources(
    FetchVideoSources event,
    Emitter<MovieState> emit,
  ) async {
    try {
      final sources = await getVideoSources();
      emit(VideoSourcesLoaded(sources: sources));
    } catch (e) {
      emit(MovieError(message: 'Failed to fetch video sources: ${e.toString()}'));
    }
  }

  Future<void> _onSelectCategory(
    SelectCategory event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      final movies = await getDoubanMovies(
        type: event.type,
        tag: event.category,
      );
      emit(DoubanMoviesLoaded(
        movies: movies,
        category: event.category,
        type: event.type,
      ));
    } catch (e) {
      emit(MovieError(message: 'Failed to fetch category movies: ${e.toString()}'));
    }
  }

  Future<void> _onFetchVideoDetail(
    FetchVideoDetail event,
    Emitter<MovieState> emit,
  ) async {
    emit(VideoDetailLoading());
    try {
      final videoDetail = await getVideoDetail(event.source, event.id);
      emit(VideoDetailLoaded(videoDetail: videoDetail));
    } catch (e) {
      emit(MovieError(message: 'Failed to fetch video detail: ${e.toString()}'));
    }
  }

  Future<void> _onGetVideoDetailEvent(
    GetVideoDetailEvent event,
    Emitter<MovieState> emit,
  ) async {
    emit(VideoDetailLoading());
    try {
      final videoDetail = await getVideoDetail(event.source, event.id);
      emit(VideoDetailLoaded(videoDetail: videoDetail));
    } catch (e) {
      emit(MovieError(message: 'Failed to fetch video detail: ${e.toString()}'));
    }
  }
}
