import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';

void main() {
  group('Actual Video Sources', () {
    test('Test with sample video source data', () async {
      // 创建一些模拟的视频源数据
      final sampleSources = [
        {
          'id': '1',
          'title': 'Test Movie',
          'source': 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
          'sourceName': 'Test Source',
        },
        {
          'id': '2',
          'title': 'Another Movie',
          'source':
              'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8',
          'sourceName': 'Another Source',
        }
      ];

      // 从sampleSources创建Video对象
      final videoObjects = sampleSources.map((sourceMap) {
        return {
          'id': sourceMap['id'] as String,
          'title': sourceMap['title'] as String,
          'source': sourceMap['source'] as String,
          'sourceName': sourceMap['sourceName'] as String,
        };
      }).toList();

      print('Video objects: $videoObjects');

      // 提取URL进行测试
      final urls = videoObjects
          .where((video) =>
              video['source'] != null && (video['source'] as String).isNotEmpty)
          .map((video) => video['source'] as String)
          .toList();

      print('URLs to test: $urls');

      // 测试分辨率检测
      final resolutionMap =
          await VideoResolutionDetector.getVideoResolutionsFromM3u8List(urls);

      print('Resolution map: $resolutionMap');

      // 验证结果
      expect(resolutionMap.length, equals(urls.length));
    });

    test('Test individual resolution detection', () async {
      // 测试单个URL的分辨率检测
      const testUrl = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

      final resolutionInfo =
          await VideoResolutionDetector.getVideoResolutionFromM3u8(testUrl);

      print('Resolution info: $resolutionInfo');

      // 验证返回的对象不为空
      expect(resolutionInfo, isNotNull);
    });
  });
}
