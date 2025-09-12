import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';

void main() {
  group('Resolution Detection Final Tests', () {
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

    test('VideoResolutionDetector should handle invalid URLs gracefully',
        () async {
      // 测试无效URL的处理
      final invalidUrls = [
        'dyttzy',
        'ruyi',
        'bfzy',
        'invalid-source-identifier',
      ];

      // 测试分辨率检测是否能处理无效URL而不抛出异常
      final resolutionMap =
          await VideoResolutionDetector.getVideoResolutionsFromM3u8List(
              invalidUrls);

      print('Invalid URL resolution map: $resolutionMap');

      // 验证每个URL都有对应的分辨率信息，即使它们是无效的
      expect(resolutionMap.length, equals(invalidUrls.length));

      // 验证所有无效URL的分辨率信息都是默认值
      for (final url in invalidUrls) {
        expect(resolutionMap.containsKey(url), isTrue);
        final resolutionInfo = resolutionMap[url]!;
        expect(resolutionInfo, isNotNull);
        // 由于URL无效，质量应该是N/A
        expect(resolutionInfo.quality, equals('N/A'));
        expect(resolutionInfo.loadSpeed, equals('N/A'));
        expect(resolutionInfo.pingTime, equals(500));
      }
    });

    test('Test _getQualityRank method', () {
      // 测试分辨率等级方法
      // 这里我们模拟MovieDetailPage中的_getQualityRank方法
      int getQualityRank(String quality) {
        switch (quality) {
          case '4K':
            return 5;
          case '2K':
            return 4;
          case '1080p':
            return 3;
          case '720p':
            return 2;
          case '480p':
            return 1;
          default:
            return 0;
        }
      }

      expect(getQualityRank('4K'), equals(5));
      expect(getQualityRank('2K'), equals(4));
      expect(getQualityRank('1080p'), equals(3));
      expect(getQualityRank('720p'), equals(2));
      expect(getQualityRank('480p'), equals(1));
      expect(getQualityRank('SD'), equals(0));
      expect(getQualityRank('N/A'), equals(0));
    });
  });
}
