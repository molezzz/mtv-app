import 'package:mtv_app/src/features/movies/domain/entities/movie.dart';
import 'package:mtv_app/src/features/movies/domain/repositories/movie_repository.dart';

class GetPopularMovies {
  final MovieRepository repository;

  GetPopularMovies(this.repository);

  Future<List<Movie>> call() async {
    return await repository.getPopularMovies();
  }
}
