import 'package:mtv_app/src/features/movies/domain/entities/movie.dart';

abstract class MovieRepository {
  Future<List<Movie>> getPopularMovies();
}
