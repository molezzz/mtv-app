import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';

void main() {
  group('VideoResolutionDetector Tests', () {
    test('测试VideoResolutionInfo对象创建', () {
      final info = VideoResolutionInfo(
        quality: '1080p',
        loadSpeed: '1.5 MB/s',
        pingTime: 100,
      );

      expect(info.quality, equals('1080p'));
      expect(info.loadSpeed, equals('1.5 MB/s'));
      expect(info.pingTime, equals(100));
    });
  });
}
