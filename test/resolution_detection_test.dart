import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';

void main() {
  group('Resolution Detection', () {
    test('VideoResolutionDetector should work with sample data', () async {
      // 创建一些测试视频源
      final videoSources = [
        const Video(
          id: '1',
          title: 'Test Video 1',
          source: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
          sourceName: 'Test Source 1',
        ),
        const Video(
          id: '2',
          title: 'Test Video 2',
          source:
              'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8',
          sourceName: 'Test Source 2',
        ),
      ];

      // 提取URL进行测试
      final urls = videoSources
          .where((video) => video.source != null && video.source!.isNotEmpty)
          .map((video) => video.source!)
          .toList();

      print('Testing URLs: $urls');

      // 测试批量检测功能
      final resolutionMap =
          await VideoResolutionDetector.getVideoResolutionsFromM3u8List(urls);

      print('Resolution map: $resolutionMap');

      expect(resolutionMap.length, greaterThan(0));
    });

    test('VideoResolutionDetector should handle invalid URLs', () async {
      // 测试无效URL的处理
      final invalidUrls = [
        'https://invalid-url-that-does-not-exist.com/invalid.m3u8',
        '',
        null,
      ].where((url) => url != null).cast<String>().toList();

      final resolutionMap =
          await VideoResolutionDetector.getVideoResolutionsFromM3u8List(
              invalidUrls);

      print('Invalid URL resolution map: $resolutionMap');

      // 即使URL无效，也应该返回一个空的或默认的结果映射
      expect(resolutionMap, isNotNull);
    });
  });
}
