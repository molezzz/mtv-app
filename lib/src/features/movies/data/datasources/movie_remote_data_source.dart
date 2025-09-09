import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:mtv_app/src/features/movies/data/models/movie_model.dart';

abstract class MovieRemoteDataSource {
  Future<List<MovieModel>> getPopularMovies();
}

class MovieRemoteDataSourceImpl implements MovieRemoteDataSource {
  final ApiClient _apiClient;

  MovieRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<MovieModel>> getPopularMovies() async {
    try {
      final response = await _apiClient.dio.get(
        '/movie/popular',
      );
      final movies = (response.data['results'] as List)
          .map((movieJson) => MovieModel.fromJson(movieJson))
          .toList();
      return movies;
    } catch (e) {
      throw Exception('Failed to load popular movies');
    }
  }
}
