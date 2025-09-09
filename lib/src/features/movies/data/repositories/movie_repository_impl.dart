import 'package:mtv_app/src/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:mtv_app/src/features/movies/domain/entities/movie.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/features/movies/domain/entities/douban_movie.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video_detail.dart';
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

  @override
  Future<List<Video>> searchVideos(String query) async {
    final videoModels = await remoteDataSource.searchVideos(query);
    final videos = videoModels
        .map((model) => Video(
              id: model.id,
              title: model.title,
              description: model.description,
              pic: model.pic,
              year: model.year,
              note: model.note,
              type: model.type,
              source: model.source,
              sourceName: model.sourceName,
            ))
        .toList();
    return videos;
  }

  @override
  Future<List<Video>> searchVideosFromSource(String query, String resourceId) async {
    final videoModels = await remoteDataSource.searchVideosFromSource(query, resourceId);
    final videos = videoModels
        .map((model) => Video(
              id: model.id,
              title: model.title,
              description: model.description,
              pic: model.pic,
              year: model.year,
              note: model.note,
              type: model.type,
              source: model.source,
              sourceName: model.sourceName,
            ))
        .toList();
    return videos;
  }

  @override
  Future<List<DoubanMovie>> getDoubanMovies({
    required String type,
    required String tag,
    int pageSize = 20,
    int pageStart = 0,
  }) async {
    final movieModels = await remoteDataSource.getDoubanMovies(
      type: type,
      tag: tag,
      pageSize: pageSize,
      pageStart: pageStart,
    );
    final movies = movieModels
        .map((model) => DoubanMovie(
              id: model.id,
              title: model.title,
              pic: model.pic,
              year: model.year,
              rating: model.rating,
              url: model.url,
              genres: model.genres,
              directors: model.directors,
              casts: model.casts,
            ))
        .toList();
    return movies;
  }

  @override
  Future<List<DoubanMovie>> getDoubanCategories({
    required String kind,
    required String category,
    required String type,
    int limit = 20,
    int start = 0,
  }) async {
    final movieModels = await remoteDataSource.getDoubanCategories(
      kind: kind,
      category: category,
      type: type,
      limit: limit,
      start: start,
    );
    final movies = movieModels
        .map((model) => DoubanMovie(
              id: model.id,
              title: model.title,
              pic: model.pic,
              year: model.year,
              rating: model.rating,
              url: model.url,
              genres: model.genres,
              directors: model.directors,
              casts: model.casts,
            ))
        .toList();
    return movies;
  }

  @override
  Future<List<Map<String, dynamic>>> getVideoSources() async {
    return await remoteDataSource.getVideoSources();
  }

  @override
  Future<VideoDetail> getVideoDetail(String source, String id) async {
    final videoDetailModel = await remoteDataSource.getVideoDetail(source, id);
    return VideoDetail(
      id: videoDetailModel.id,
      title: videoDetailModel.title,
      poster: videoDetailModel.poster,
      source: videoDetailModel.source,
      sourceName: videoDetailModel.sourceName,
      desc: videoDetailModel.desc,
      type: videoDetailModel.type,
      year: videoDetailModel.year,
      area: videoDetailModel.area,
      director: videoDetailModel.director,
      actor: videoDetailModel.actor,
      remarks: videoDetailModel.remarks,
      episodes: videoDetailModel.episodes,
    );
  }
}
