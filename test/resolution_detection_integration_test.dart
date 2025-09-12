import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/features/movies/data/models/video_detail_model.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';

void main() {
  group('Resolution Detection Integration Tests', () {
    test('Video resolution detection should work with real video URLs',
        () async {
      // 创建一个包含真实M3U8 URL的测试视频源
      const testVideo = Video(
        id: 'test123',
        title: 'Test Video',
        source: 'test_source',
        sourceName: 'Test Source',
      );

      // 使用一个公开可用的M3U8测试URL
      const testUrl = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

      // 测试分辨率检测器是否能正确处理真实URL
      final resolutionInfo =
          await VideoResolutionDetector.getVideoResolutionFromM3u8(testUrl);

      // 验证结果
      expect(resolutionInfo, isNotNull);
      expect(resolutionInfo.quality, isNotNull);
      expect(resolutionInfo.loadSpeed, isNotNull);
      expect(resolutionInfo.pingTime, greaterThan(0));

      print('Resolution Info: $resolutionInfo');
    });
  });
}
