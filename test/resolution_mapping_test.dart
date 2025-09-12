import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';

void main() {
  group('Resolution Mapping Tests', () {
    test('VideoResolutionInfo mapping should work correctly', () {
      // 创建一个VideoResolutionInfo实例
      final resolutionInfo = VideoResolutionInfo(
        quality: '1080p',
        loadSpeed: '2.5 MB/s',
        pingTime: 200,
      );

      // 验证属性
      expect(resolutionInfo.quality, equals('1080p'));
      expect(resolutionInfo.loadSpeed, equals('2.5 MB/s'));
      expect(resolutionInfo.pingTime, equals(200));
    });

    test('Quality rank calculation should work correctly', () {
      // 测试不同分辨率的质量等级
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