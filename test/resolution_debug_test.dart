import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';

void main() {
  test('Test resolution detection with sample M3U8 URL', () async {
    // 使用一个公开的M3U8测试URL
    const testUrl = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

    try {
      final resolutionInfo =
          await VideoResolutionDetector.getVideoResolutionFromM3u8(testUrl);
      print('Resolution Info: $resolutionInfo');

      expect(resolutionInfo, isNotNull);
    } catch (e) {
      print('Error detecting resolution: $e');
    }
  });
}
