import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_popular_movies.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_event.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_state.dart';

class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final GetPopularMovies getPopularMovies;

  MovieBloc({required this.getPopularMovies}) : super(MovieInitial()) {
    on<FetchPopularMovies>((event, emit) async {
      emit(MovieLoading());
      try {
        final movies = await getPopularMovies();
        emit(MovieLoaded(movies: movies));
      } catch (e) {
        emit(const MovieError(message: 'Failed to fetch movies'));
      }
    });
  }
}
