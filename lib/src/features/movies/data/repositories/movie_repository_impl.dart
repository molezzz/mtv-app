import 'package:mtv_app/src/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:mtv_app/src/features/movies/domain/entities/movie.dart';
import 'package:mtv_app/src/features/movies/domain/repositories/movie_repository.dart';

class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource remoteDataSource;

  MovieRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Movie>> getPopularMovies() async {
    final movieModels = await remoteDataSource.getPopularMovies();
    final movies = movieModels
        .map((model) => Movie(
              id: model.id,
              title: model.title,
              overview: model.overview,
              posterPath: model.posterPath,
            ))
        .toList();
    return movies;
  }
}
