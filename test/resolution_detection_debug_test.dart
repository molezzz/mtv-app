import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/features/movies/data/repositories/movie_repository_impl.dart';
import 'package:mtv_app/src/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Resolution Detection Debug Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('Video entity should properly store quality information', () {
      // 创建一个包含质量信息的视频对象
      const video = Video(
        id: 'test123',
        title: 'Test Video',
        source: 'test_source',
        sourceName: 'Test Source',
        quality: '1080p', // 添加质量信息
      );

      // 验证视频对象正确创建
      expect(video.id, equals('test123'));
      expect(video.title, equals('Test Video'));
      expect(video.source, equals('test_source'));
      expect(video.sourceName, equals('Test Source'));
      expect(video.quality, equals('1080p'));
    });

    // 这个测试需要网络连接和有效的API服务器
    test('Test video detail retrieval', () async {
      // 模拟SharedPreferences
      SharedPreferences.setMockInitialValues(
          {'api_server_address': 'https://tv.lightndust.cn'});

      final prefs = await SharedPreferences.getInstance();
      final serverAddress = prefs.getString('api_server_address');

      if (serverAddress != null) {
        print('Server address: $serverAddress');
        final apiClient = ApiClient(baseUrl: serverAddress);
        final repository = MovieRepositoryImpl(
          remoteDataSource: MovieRemoteDataSourceImpl(apiClient),
        );

        try {
          // 尝试获取一个测试视频的详情
          // 注意：这需要一个有效的source和id
          final videoDetail = await repository.getVideoDetail('ruyi', '56843');
          print('Video detail retrieved successfully');
          print('Episodes count: ${videoDetail.episodes?.length ?? 0}');

          if (videoDetail.episodes != null &&
              videoDetail.episodes!.isNotEmpty) {
            print('First episode URL: ${videoDetail.episodes!.first}');
          }
        } catch (e) {
          print('Error retrieving video detail: $e');
        }
      } else {
        print('No server address configured');
      }
    });
  });
}
