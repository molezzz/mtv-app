import 'package:mtv_app/src/features/movies/domain/entities/douban_movie.dart';
import 'package:mtv_app/src/features/movies/domain/repositories/movie_repository.dart';

class GetDoubanCategories {
  final MovieRepository repository;

  GetDoubanCategories(this.repository);

  Future<List<DoubanMovie>> call({
    required String kind,
    required String category,
    required String type,
    int limit = 20,
    int start = 0,
  }) async {
    return await repository.getDoubanCategories(
      kind: kind,
      category: category,
      type: type,
      limit: limit,
      start: start,
    );
  }
}