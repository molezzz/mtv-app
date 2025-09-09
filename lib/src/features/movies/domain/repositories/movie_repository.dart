import 'package:mtv_app/src/features/movies/domain/entities/movie.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/features/movies/domain/entities/douban_movie.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video_detail.dart';

abstract class MovieRepository {
  Future<List<Movie>> getPopularMovies();
  Future<List<Video>> searchVideos(String query);
  Future<List<Video>> searchVideosFromSource(String query, String resourceId);
  Future<List<DoubanMovie>> getDoubanMovies({
    required String type,
    required String tag,
    int pageSize = 20,
    int pageStart = 0,
  });
  Future<List<DoubanMovie>> getDoubanCategories({
    required String kind,
    required String category,
    required String type,
    int limit = 20,
    int start = 0,
  });
  Future<List<Map<String, dynamic>>> getVideoSources();
  Future<VideoDetail> getVideoDetail(String source, String id);
}
