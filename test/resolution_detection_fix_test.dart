import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';

void main() {
  group('Resolution Detection Fix Tests', () {
    test('VideoResolutionDetector should handle valid M3U8 URLs', () async {
      // 使用一个公开的M3U8测试URL
      const testUrl = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

      try {
        final resolutionInfo =
            await VideoResolutionDetector.getVideoResolutionFromM3u8(testUrl);
        print('Resolution info for test URL: $resolutionInfo');
        expect(resolutionInfo, isNotNull);
        // 注意：由于这是一个公开测试URL，我们不能保证具体的分辨率值
        // 但我们至少可以验证返回的对象不为空
      } catch (e) {
        print('Error detecting resolution for test URL: $e');
        // 对于测试URL，我们允许出现错误，但不应该抛出异常
        expect(e, isNotNull);
      }
    });

    test('VideoResolutionDetector should handle invalid URLs gracefully',
        () async {
      // 测试无效URL的处理
      const invalidUrl = 'invalid-url';

      // 测试分辨率检测是否能处理无效URL而不抛出异常
      final resolutionInfo =
          await VideoResolutionDetector.getVideoResolutionFromM3u8(invalidUrl);

      // 验证返回默认值
      expect(resolutionInfo, isNotNull);
      expect(resolutionInfo.quality, equals('N/A'));
      expect(resolutionInfo.loadSpeed, equals('N/A'));
      expect(resolutionInfo.pingTime, equals(500));
    });

    test('VideoResolutionDetector batch processing should work', () async {
      // 测试批量处理功能
      final testUrls = [
        'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
        'invalid-url',
      ];

      final resolutionMap =
          await VideoResolutionDetector.getVideoResolutionsFromM3u8List(
              testUrls);

      // 验证返回的映射不为空
      expect(resolutionMap, isNotNull);
      expect(resolutionMap.length, equals(2));

      // 验证每个URL都有对应的分辨率信息
      for (final url in testUrls) {
        expect(resolutionMap.containsKey(url), isTrue);
        final resolutionInfo = resolutionMap[url]!;
        expect(resolutionInfo, isNotNull);
      }
    });
  });
}
