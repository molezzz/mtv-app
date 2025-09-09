import 'package:mtv_app/src/features/movies/domain/repositories/movie_repository.dart';

class GetVideoSources {
  final MovieRepository repository;

  GetVideoSources(this.repository);

  Future<List<Map<String, dynamic>>> call() async {
    return await repository.getVideoSources();
  }
}