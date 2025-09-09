import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:mtv_app/src/core/services/image_proxy_service.dart';
import 'package:mtv_app/src/features/movies/data/models/movie_model.dart';
import 'package:mtv_app/src/features/movies/data/models/video_model.dart';
import 'package:mtv_app/src/features/movies/data/models/douban_movie_model.dart';

abstract class MovieRemoteDataSource {
  Future<List<MovieModel>> getPopularMovies();
  Future<List<VideoModel>> searchVideos(String query);
  Future<List<VideoModel>> searchVideosFromSource(String query, String resourceId);
  Future<List<DoubanMovieModel>> getDoubanMovies({
    required String type,
    required String tag,
    int pageSize = 20,
    int pageStart = 0,
  });
  Future<List<DoubanMovieModel>> getDoubanCategories({
    required String kind,
    required String category,
    required String type,
    int limit = 20,
    int start = 0,
  });
  Future<List<Map<String, dynamic>>> getVideoSources();
}

class MovieRemoteDataSourceImpl implements MovieRemoteDataSource {
  final ApiClient _apiClient;
  final ImageProxyService _imageProxyService;

  MovieRemoteDataSourceImpl(this._apiClient) 
      : _imageProxyService = ImageProxyService(_apiClient);

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

  @override
  Future<List<VideoModel>> searchVideos(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/search',
        queryParameters: {'q': query},
      );
      final videos = (response.data['list'] as List? ?? [])
          .map((videoJson) => VideoModel.fromJson(videoJson))
          .toList();
      return videos;
    } catch (e) {
      throw Exception('Failed to search videos: $e');
    }
  }

  @override
  Future<List<VideoModel>> searchVideosFromSource(String query, String resourceId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/search/one',
        queryParameters: {
          'q': query,
          'resourceId': resourceId,
        },
      );
      final videos = (response.data['list'] as List? ?? [])
          .map((videoJson) => VideoModel.fromJson(videoJson))
          .toList();
      return videos;
    } catch (e) {
      throw Exception('Failed to search videos from source: $e');
    }
  }

  @override
  Future<List<DoubanMovieModel>> getDoubanMovies({
    required String type,
    required String tag,
    int pageSize = 20,
    int pageStart = 0,
  }) async {
    try {
      print('Making API call to /api/douban with params: type=$type, tag=$tag');
      final response = await _apiClient.dio.get(
        '/api/douban',
        queryParameters: {
          'type': type,
          'tag': tag,
          'pageSize': pageSize,
          'pageStart': pageStart,
        },
      );
      
      print('API Response status: ${response.statusCode}');
      print('API Response data type: ${response.data.runtimeType}');
      print('API Response data: ${response.data}');
      
      // 检查API返回格式
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        // 如果是新的API格式，使用list字段
        if (data.containsKey('list')) {
          final movieList = data['list'] as List? ?? [];
          print('Found ${movieList.length} movies in list field');
          final movies = movieList
              .map((movieJson) {
                // 创建新的Map以避免修改原始数据
                final Map<String, dynamic> newMovieJson = Map<String, dynamic>.from(movieJson);
                // 处理图片代理
                if (newMovieJson['poster'] != null) {
                  final originalUrl = newMovieJson['poster'] as String;
                  // 只有当URL还没有被代理过时才进行代理
                  if (!originalUrl.contains('/api/image-proxy')) {
                    final proxiedUrl = _imageProxyService.getProxiedImageUrl(originalUrl);
                    newMovieJson['poster'] = proxiedUrl;
                    print('Image proxy: $originalUrl -> $proxiedUrl');
                  } else {
                    print('Image already proxied: $originalUrl');
                  }
                }
                return DoubanMovieModel.fromJson(newMovieJson);
              })
              .toList();
          return movies;
        }
        
        // 如果是豆瓣原始格式，使用subjects字段
        if (data.containsKey('subjects')) {
          final movieList = data['subjects'] as List? ?? [];
          print('Found ${movieList.length} movies in subjects field');
          final movies = movieList
              .map((movieJson) {
                // 处理图片代理
                if (movieJson['poster'] != null) {
                  movieJson['poster'] = _imageProxyService.getProxiedImageUrl(movieJson['poster']);
                }
                return DoubanMovieModel.fromJson(movieJson);
              })
              .toList();
          return movies;
        }
      }
      
      // 如果直接是数组格式
      if (response.data is List) {
        final movieList = response.data as List;
        print('Found ${movieList.length} movies in direct array');
        final movies = movieList
            .map((movieJson) {
              // 处理图片代理
              if (movieJson['poster'] != null) {
                movieJson['poster'] = _imageProxyService.getProxiedImageUrl(movieJson['poster']);
              }
              return DoubanMovieModel.fromJson(movieJson);
            })
            .toList();
        return movies;
      }
      
      print('No movies found in response');
      return [];
    } catch (e) {
      print('Exception in getDoubanMovies: $e');
      throw Exception('Failed to load douban movies: $e');
    }
  }

  @override
  Future<List<DoubanMovieModel>> getDoubanCategories({
    required String kind,
    required String category,
    required String type,
    int limit = 20,
    int start = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/douban/categories',
        queryParameters: {
          'kind': kind,
          'category': category,
          'type': type,
          'limit': limit,
          'start': start,
        },
      );
      
      // 检查API返回格式
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        // 如果是新的API格式，使用list字段
        if (data.containsKey('list')) {
          final movies = (data['list'] as List? ?? [])
              .map((movieJson) {
                // 处理图片代理
                if (movieJson['poster'] != null) {
                  movieJson['poster'] = _imageProxyService.getProxiedImageUrl(movieJson['poster']);
                }
                return DoubanMovieModel.fromJson(movieJson);
              })
              .toList();
          return movies;
        }
        
        // 如果是豆瓣原始格式，使用subjects字段
        if (data.containsKey('subjects')) {
          final movies = (data['subjects'] as List? ?? [])
              .map((movieJson) {
                // 处理图片代理
                if (movieJson['poster'] != null) {
                  movieJson['poster'] = _imageProxyService.getProxiedImageUrl(movieJson['poster']);
                }
                return DoubanMovieModel.fromJson(movieJson);
              })
              .toList();
          return movies;
        }
      }
      
      // 如果直接是数组格式
      if (response.data is List) {
        final movies = (response.data as List)
            .map((movieJson) {
              // 处理图片代理
              if (movieJson['poster'] != null) {
                movieJson['poster'] = _imageProxyService.getProxiedImageUrl(movieJson['poster']);
              }
              return DoubanMovieModel.fromJson(movieJson);
            })
            .toList();
        return movies;
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to load douban categories: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getVideoSources() async {
    try {
      final response = await _apiClient.dio.get('/api/search/resources');
      return List<Map<String, dynamic>>.from(response.data ?? []);
    } catch (e) {
      throw Exception('Failed to load video sources: $e');
    }
  }
}
