import 'package:mtv_app/src/features/movies/domain/entities/douban_movie.dart';
import 'package:mtv_app/src/features/movies/domain/repositories/movie_repository.dart';

class GetDoubanMovies {
  final MovieRepository repository;

  GetDoubanMovies(this.repository);

  Future<List<DoubanMovie>> call({
    required String type,
    required String tag,
    int pageSize = 20,
    int pageStart = 0,
  }) async {
    return await repository.getDoubanMovies(
      type: type,
      tag: tag,
      pageSize: pageSize,
      pageStart: pageStart,
    );
  }
}