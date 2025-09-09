import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/features/movies/domain/repositories/movie_repository.dart';

class SearchVideos {
  final MovieRepository repository;

  SearchVideos(this.repository);

  Future<List<Video>> call(String query) async {
    return await repository.searchVideos(query);
  }
}