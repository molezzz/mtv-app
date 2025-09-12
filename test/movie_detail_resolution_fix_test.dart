import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';

void main() {
  group('Movie Detail Resolution Fix Tests', () {
    test('Video entity should properly store quality information', () {
      // 创建一个包含质量信息的视频对象
      final video = Video(
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

    test('Resolution mapping should work correctly', () {
      // 模拟MovieDetailPage中的分辨率信息映射逻辑
      final Map<String, VideoResolutionInfo> resolutionInfoMap = {};
      
      // 创建一些测试数据
      final video1 = Video(
        id: 'video1',
        title: 'Test Video 1',
        source: 'source1',
        sourceName: 'Source 1',
      );
      
      final video2 = Video(
        id: 'video2',
        title: 'Test Video 2',
        source: 'source2',
        sourceName: 'Source 2',
      );
      
      final resolutionInfo1 = VideoResolutionInfo(
        quality: '1080p',
        loadSpeed: '2.5 MB/s',
        pingTime: 150,
      );
      
      final resolutionInfo2 = VideoResolutionInfo(
        quality: '720p',
        loadSpeed: '1.8 MB/s',
        pingTime: 200,
      );
      
      // 模拟将分辨率信息存储到映射中
      resolutionInfoMap[video1.id] = resolutionInfo1;
      resolutionInfoMap[video2.id] = resolutionInfo2;
      
      // 验证映射是否正确
      expect(resolutionInfoMap.length, equals(2));
      expect(resolutionInfoMap.containsKey(video1.id), isTrue);
      expect(resolutionInfoMap.containsKey(video2.id), isTrue);
      
      final retrievedInfo1 = resolutionInfoMap[video1.id];
      final retrievedInfo2 = resolutionInfoMap[video2.id];
      
      expect(retrievedInfo1, isNotNull);
      expect(retrievedInfo1!.quality, equals('1080p'));
      expect(retrievedInfo1.loadSpeed, equals('2.5 MB/s'));
      expect(retrievedInfo1.pingTime, equals(150));
      
      expect(retrievedInfo2, isNotNull);
      expect(retrievedInfo2!.quality, equals('720p'));
      expect(retrievedInfo2.loadSpeed, equals('1.8 MB/s'));
      expect(retrievedInfo2.pingTime, equals(200));
    });
  });
}