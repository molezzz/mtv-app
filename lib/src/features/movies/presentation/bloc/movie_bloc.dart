import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_popular_movies.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_douban_movies.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_douban_categories.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/search_videos.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_video_sources.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_video_detail.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_event.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_state.dart';

class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final GetPopularMovies getPopularMovies;
  final GetDoubanMovies getDoubanMovies;
  final GetDoubanCategories getDoubanCategories;
  final SearchVideos searchVideos;
  final GetVideoSources getVideoSources;
  final GetVideoDetail getVideoDetail;

  MovieBloc({
    required this.getPopularMovies,
    required this.getDoubanMovies,
    required this.getDoubanCategories,
    required this.searchVideos,
    required this.getVideoSources,
    required this.getVideoDetail,
  }) : super(MovieInitial()) {
    on<FetchPopularMovies>(_onFetchPopularMovies);
    on<FetchDoubanMovies>(_onFetchDoubanMovies);
    on<FetchDoubanCategories>(_onFetchDoubanCategories);
    on<SearchVideosEvent>(_onSearchVideos);
    on<FetchVideoSources>(_onFetchVideoSources);
    on<SelectCategory>(_onSelectCategory);
    on<FetchVideoDetail>(_onFetchVideoDetail);
    on<GetVideoDetailEvent>(_onGetVideoDetailEvent);
    on<FetchMoreDoubanMovies>(_onFetchMoreDoubanMovies);
    on<FetchMoreDoubanCategories>(_onFetchMoreDoubanCategories);
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
        hasReachedMax: movies.isEmpty,
      ));
    } catch (e) {
      print('Error fetching douban movies: $e');
      emit(MovieError(
          message: 'Failed to fetch douban movies: ${e.toString()}'));
    }
  }

  Future<void> _onFetchMoreDoubanMovies(
    FetchMoreDoubanMovies event,
    Emitter<MovieState> emit,
  ) async {
    final currentState = state;
    if (currentState is DoubanMoviesLoaded && !currentState.hasReachedMax) {
      try {
        final movies = await getDoubanMovies(
          type: event.type,
          tag: event.tag,
          pageStart: event.pageStart,
        );
        if (movies.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          emit(
            currentState.copyWith(
              movies: currentState.movies + movies,
              hasReachedMax: false,
            ),
          );
        }
      } catch (e) {
        emit(MovieError(
            message: 'Failed to fetch more douban movies: ${e.toString()}'));
      }
    }
  }

  Future<void> _onFetchDoubanCategories(
    FetchDoubanCategories event,
    Emitter<MovieState> emit,
  ) async {
    emit(MovieLoading());
    try {
      print(
          'Fetching douban categories: kind=${event.kind}, category=${event.category}, type=${event.type}');
      final movies = await getDoubanCategories(
        kind: event.kind,
        category: event.category,
        type: event.type,
        limit: event.limit,
        start: event.start,
      );
      print('Received ${movies.length} movies from categories');
      emit(DoubanMoviesLoaded(
        movies: movies,
        category: event.type,
        type: event.category,
        hasReachedMax: movies.isEmpty,
      ));
    } catch (e) {
      print('Error fetching douban categories: $e');
      emit(MovieError(
          message: 'Failed to fetch douban categories: ${e.toString()}'));
    }
  }

  Future<void> _onFetchMoreDoubanCategories(
    FetchMoreDoubanCategories event,
    Emitter<MovieState> emit,
  ) async {
    final currentState = state;
    if (currentState is DoubanMoviesLoaded && !currentState.hasReachedMax) {
      try {
        final movies = await getDoubanCategories(
          kind: event.kind,
          category: event.category,
          type: event.type,
          start: event.start,
        );
        if (movies.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          emit(
            currentState.copyWith(
              movies: currentState.movies + movies,
              hasReachedMax: false,
            ),
          );
        }
      } catch (e) {
        emit(MovieError(
            message:
                'Failed to fetch more douban categories: ${e.toString()}'));
      }
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
      emit(MovieError(
          message: 'Failed to fetch video sources: ${e.toString()}'));
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
        hasReachedMax: movies.isEmpty,
      ));
    } catch (e) {
      emit(MovieError(
          message: 'Failed to fetch category movies: ${e.toString()}'));
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
      emit(
          MovieError(message: 'Failed to fetch video detail: ${e.toString()}'));
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
      emit(
          MovieError(message: 'Failed to fetch video detail: ${e.toString()}'));
    }
  }

  Future<dynamic> getVideoDetailForCasting(String source, String id) async {
    try {
      final videoDetail = await getVideoDetail(source, id);
      return videoDetail;
    } catch (e) {
      // You might want to handle this error more gracefully
      rethrow;
    }
  }
}
