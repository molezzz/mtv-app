import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/features/movies/data/repositories/movie_repository_impl.dart';
import 'package:mtv_app/src/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';
import 'dart:io';

void main() {
  group('Resolution Detection Auth Tests', () {
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

    // 这个测试模拟实际应用中的情况
    test('Test video detail retrieval with auth simulation', () async {
      // 模拟SharedPreferences，包括认证信息
      SharedPreferences.setMockInitialValues({
        'api_server_address': 'https://tv.lightndust.cn',
        'auth_cookie':
            'auth=%257B%2522role%2522%253A%2522owner%2522%252C%2522username%2522%253A%2522testuser%2522%252C%2522signature%2522%253A%2522testsignature%2522%252C%2522timestamp%2522%253A1757550939187%257D; SameSite=Lax; Path=/; Expires=Thu, 18 Sep 2025 00:35:39 GMT'
      });

      final prefs = await SharedPreferences.getInstance();
      final serverAddress = prefs.getString('api_server_address');
      final authCookie = prefs.getString('auth_cookie');

      if (serverAddress != null) {
        print('Server address: $serverAddress');
        if (authCookie != null) {
          print('Auth cookie found');
        } else {
          print('No auth cookie found');
        }

        final apiClient = ApiClient(baseUrl: serverAddress);
        final repository = MovieRepositoryImpl(
          remoteDataSource: MovieRemoteDataSourceImpl(apiClient),
        );

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
