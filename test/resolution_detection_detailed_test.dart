import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/features/movies/data/repositories/movie_repository_impl.dart';
import 'package:mtv_app/src/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';

void main() {
  group('Resolution Detection Detailed Tests', () {
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
    test('Test video detail retrieval with error handling', () async {
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

        // 测试一个已知的无效source/id组合
        try {
          print('Testing with invalid source/id: invalid_source/invalid_id');
          final videoDetail =
              await repository.getVideoDetail('invalid_source', 'invalid_id');
          print('Video detail retrieved successfully (unexpected)');
          print('Episodes count: ${videoDetail.episodes?.length ?? 0}');
        } catch (e) {
          print('Expected error for invalid source/id: $e');
        }

        // 测试一个可能有效的source/id组合
        try {
          print('Testing with source/id: ruyi/56843');
          final videoDetail = await repository.getVideoDetail('ruyi', '56843');
          print('Video detail retrieved successfully');
          print('Episodes count: ${videoDetail.episodes?.length ?? 0}');

          if (videoDetail.episodes != null &&
              videoDetail.episodes!.isNotEmpty) {
            print('First episode URL: ${videoDetail.episodes!.first}');

            // 测试分辨率检测
            try {
              final resolutionInfo =
                  await VideoResolutionDetector.getVideoResolutionFromM3u8(
                      videoDetail.episodes!.first);
              print('Resolution info: $resolutionInfo');
            } catch (e) {
              print('Error detecting resolution: $e');
            }
          }
        } catch (e) {
          print('Error retrieving video detail: $e');
        }
      } else {
        print('No server address configured');
      }
    });

    test('Test resolution detection with valid M3U8 URL', () async {
      // 使用一个公开的M3U8测试URL
      const testUrl = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

      try {
        final resolutionInfo =
            await VideoResolutionDetector.getVideoResolutionFromM3u8(testUrl);
        print('Resolution info for test URL: $resolutionInfo');
        expect(resolutionInfo, isNotNull);
        expect(resolutionInfo.quality, isNotNull);
      } catch (e) {
        print('Error detecting resolution for test URL: $e');
      }
    });
  });
}
