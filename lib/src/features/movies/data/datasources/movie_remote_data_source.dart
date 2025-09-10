import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:mtv_app/src/core/services/image_proxy_service.dart';
import 'package:mtv_app/src/core/utils/title_matcher.dart';
import 'package:mtv_app/src/features/movies/data/models/movie_model.dart';
import 'package:mtv_app/src/features/movies/data/models/video_model.dart';
import 'package:mtv_app/src/features/movies/data/models/douban_movie_model.dart';
import 'package:mtv_app/src/features/movies/data/models/video_detail_model.dart';
import 'package:mtv_app/src/features/movies/data/models/play_record_model.dart';

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
  Future<VideoDetailModel> getVideoDetail(String source, String id);
  Future<Map<String, PlayRecordModel>> getPlayRecords();
  Future<bool> savePlayRecord(String key, PlayRecordModel record);
  Future<bool> deletePlayRecord(String key);
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
      
      // 搜索API返回的格式是 {"results": [...]}
      // 但字段名与VideoModel期望的不同，需要转换
      final videos = (response.data['results'] as List? ?? [])
          .map((searchJson) {
            // 确保所有必需字段都有非空值
            final convertedJson = <String, dynamic>{
              'vod_id': (searchJson['id']?.toString() ?? '').isEmpty ? 'unknown' : searchJson['id']?.toString() ?? 'unknown',
              'vod_name': (searchJson['title']?.toString() ?? '').isEmpty ? 'Unknown Title' : searchJson['title']?.toString() ?? 'Unknown Title',
              'vod_content': searchJson['desc']?.toString(),
              'vod_pic': searchJson['poster']?.toString(),
              'vod_year': searchJson['year']?.toString(),
              'vod_remarks': searchJson['class']?.toString(), // 使用class字段作为影片分类
              'type_name': searchJson['type_name']?.toString(),
              'source': searchJson['source']?.toString(),
              'source_name': searchJson['source_name']?.toString(), // 添加source_name映射
            };
            return VideoModel.fromJson(convertedJson);
          })
          .toList();
          
      // 对搜索结果进行二次过滤，使用影片名精确匹配
      final filteredVideos = videos.where((video) {
        final videoTitle = video.title ?? '';
        
        // 使用智能标题匹配器进行匹配
        final isMatched = TitleMatcher.isMatch(query, videoTitle);
        
        // 调试输出（开发环境可启用）
        if (isMatched) {
          print('✓ 匹配成功: "$query" -> "$videoTitle"');
        }
        
        return isMatched;
      }).toList();
      
      // 如果精确匹配没有结果，返回相似度最高的前3个结果
      if (filteredVideos.isEmpty && videos.isNotEmpty) {
        print('精确匹配无结果，使用相似度匹配');
        
        // 计算所有结果的相似度
        final videosWithSimilarity = videos.map((video) {
          final similarity = TitleMatcher.calculateSimilarity(query, video.title ?? '');
          return {'video': video, 'similarity': similarity};
        }).toList();
        
        // 按相似度降序排序
        videosWithSimilarity.sort((a, b) => 
          (b['similarity'] as double).compareTo(a['similarity'] as double));
        
        // 返回相似度大于0.6的结果，最多3个
        final similarResults = videosWithSimilarity
            .where((item) => (item['similarity'] as double) >= 0.6)
            .take(3)
            .map((item) => item['video'] as VideoModel)
            .toList();
            
        if (similarResults.isNotEmpty) {
          print('找到${similarResults.length}个相似结果');
          return similarResults;
        }
      }
      
      print('原始搜索结果数量: ${videos.length}');
      print('过滤后结果数量: ${filteredVideos.length}');
      
      return filteredVideos;
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
      
      // 搜索API返回的格式是 {"results": [...]}
      // 但字段名与VideoModel期望的不同，需要转换
      final videos = (response.data['results'] as List? ?? [])
          .map((searchJson) {
            // 确保所有必需字段都有非空值
            final convertedJson = <String, dynamic>{
              'vod_id': (searchJson['id']?.toString() ?? '').isEmpty ? 'unknown' : searchJson['id']?.toString() ?? 'unknown',
              'vod_name': (searchJson['title']?.toString() ?? '').isEmpty ? 'Unknown Title' : searchJson['title']?.toString() ?? 'Unknown Title',
              'vod_content': searchJson['desc']?.toString(),
              'vod_pic': searchJson['poster']?.toString(),
              'vod_year': searchJson['year']?.toString(),
              'vod_remarks': searchJson['class']?.toString(), // 使用class字段作为影片分类
              'type_name': searchJson['type_name']?.toString(),
              'source': searchJson['source']?.toString(),
              'source_name': searchJson['source_name']?.toString(), // 添加source_name映射
            };
            return VideoModel.fromJson(convertedJson);
          })
          .toList();
          
      // 对特定资源的搜索结果也进行精确过滤
      final filteredVideos = videos.where((video) {
        final videoTitle = video.title ?? '';
        final isMatched = TitleMatcher.isMatch(query, videoTitle);
        
        if (isMatched) {
          print('✓ 特定资源匹配成功: "$query" -> "$videoTitle" (源: $resourceId)');
        }
        
        return isMatched;
      }).toList();
      
      print('特定资源($resourceId)原始结果: ${videos.length}, 过滤后: ${filteredVideos.length}');
      
      return filteredVideos;
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

  @override
  Future<VideoDetailModel> getVideoDetail(String source, String id) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/detail',
        queryParameters: {
          'source': source,
          'id': id,
        },
      );
      
      // 处理图片代理
      final Map<String, dynamic> videoDetailJson = Map<String, dynamic>.from(response.data);
      if (videoDetailJson['poster'] != null) {
        final originalUrl = videoDetailJson['poster'] as String;
        if (!originalUrl.contains('/api/image-proxy')) {
          final proxiedUrl = _imageProxyService.getProxiedImageUrl(originalUrl);
          videoDetailJson['poster'] = proxiedUrl;
        }
      }
      
      return VideoDetailModel.fromJson(videoDetailJson);
    } catch (e) {
      throw Exception('Failed to load video detail: $e');
    }
  }

  @override
  Future<Map<String, PlayRecordModel>> getPlayRecords() async {
    try {
      final response = await _apiClient.dio.get('/api/playrecords');
      final Map<String, dynamic> recordsData = response.data as Map<String, dynamic>;
      
      final Map<String, PlayRecordModel> records = {};
      recordsData.forEach((key, value) {
        records[key] = PlayRecordModel.fromJson(value as Map<String, dynamic>);
      });
      
      return records;
    } catch (e) {
      throw Exception('Failed to load play records: $e');
    }
  }

  @override
  Future<bool> savePlayRecord(String key, PlayRecordModel record) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/playrecords',
        data: {
          'key': key,
          'record': record.toJson(),
        },
      );
      
      final Map<String, dynamic> result = response.data as Map<String, dynamic>;
      return result['success'] as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to save play record: $e');
    }
  }

  @override
  Future<bool> deletePlayRecord(String key) async {
    try {
      final response = await _apiClient.dio.delete(
        '/api/playrecords',
        queryParameters: {'key': key},
      );
      
      final Map<String, dynamic> result = response.data as Map<String, dynamic>;
      return result['success'] as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to delete play record: $e');
    }
  }
}