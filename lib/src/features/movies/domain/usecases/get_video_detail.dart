import 'package:mtv_app/src/features/movies/domain/entities/video_detail.dart';
import 'package:mtv_app/src/features/movies/domain/repositories/movie_repository.dart';

class GetVideoDetail {
  final MovieRepository repository;

  GetVideoDetail(this.repository);

  Future<VideoDetail> call(String source, String id) async {
    return await repository.getVideoDetail(source, id);
  }
}