import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';

void main() {
  group('Video Detail Resolution Tests', () {
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

    test('Video entity should handle null quality information', () {
      // 创建一个不包含质量信息的视频对象
      const video = Video(
        id: 'test456',
        title: 'Test Video 2',
        source: 'test_source_2',
        sourceName: 'Test Source 2',
        // 不设置quality字段，应该为null
      );

      // 验证视频对象正确创建
      expect(video.id, equals('test456'));
      expect(video.title, equals('Test Video 2'));
      expect(video.source, equals('test_source_2'));
      expect(video.sourceName, equals('Test Source 2'));
      expect(video.quality, isNull);
    });
  });
}
