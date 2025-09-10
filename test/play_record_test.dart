import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/features/movies/data/models/play_record_model.dart';

void main() {
  group('PlayRecordModel', () {
    test('should create a PlayRecordModel instance', () {
      final record = PlayRecordModel(
        title: 'Test Movie',
        sourceName: 'Test Source',
        cover: 'https://example.com/cover.jpg',
        index: 1,
        totalEpisodes: 10,
        playTime: 120,
        totalTime: 3600,
        saveTime: 1620000000,
        year: '2023',
      );

      expect(record.title, 'Test Movie');
      expect(record.sourceName, 'Test Source');
      expect(record.cover, 'https://example.com/cover.jpg');
      expect(record.index, 1);
      expect(record.totalEpisodes, 10);
      expect(record.playTime, 120);
      expect(record.totalTime, 3600);
      expect(record.saveTime, 1620000000);
      expect(record.year, '2023');
    });

    test('should serialize and deserialize correctly', () {
      final record = PlayRecordModel(
        title: 'Test Movie',
        sourceName: 'Test Source',
        cover: 'https://example.com/cover.jpg',
        index: 1,
        totalEpisodes: 10,
        playTime: 120,
        totalTime: 3600,
        saveTime: 1620000000,
        year: '2023',
      );

      final json = record.toJson();
      final deserializedRecord = PlayRecordModel.fromJson(json);

      expect(deserializedRecord.title, record.title);
      expect(deserializedRecord.sourceName, record.sourceName);
      expect(deserializedRecord.cover, record.cover);
      expect(deserializedRecord.index, record.index);
      expect(deserializedRecord.totalEpisodes, record.totalEpisodes);
      expect(deserializedRecord.playTime, record.playTime);
      expect(deserializedRecord.totalTime, record.totalTime);
      expect(deserializedRecord.saveTime, record.saveTime);
      expect(deserializedRecord.year, record.year);
    });

    test('should handle null and empty values gracefully', () {
      // 测试空值情况
      final record = PlayRecordModel.fromJson({
        'title': null,
        'source_name': null,
        'cover': null,
        'index': null,
        'total_episodes': null,
        'play_time': null,
        'total_time': null,
        'save_time': null,
        'year': null,
      });

      // 验证默认值
      expect(record.title, '');
      expect(record.sourceName, '');
      expect(record.cover, '');
      expect(record.index, 0);
      expect(record.totalEpisodes, 0);
      expect(record.playTime, 0);
      expect(record.totalTime, 0);
      expect(record.saveTime, 0);
      expect(record.year, '');
      expect(record.searchTitle, null);
    });

    test('should handle mixed null and valid values', () {
      // 测试混合情况
      final record = PlayRecordModel.fromJson({
        'title': 'Test Movie',
        'source_name': null,
        'cover': 'https://example.com/cover.jpg',
        'index': 5,
        'total_episodes': null,
        'play_time': 120,
        'total_time': null,
        'save_time': 1620000000,
        'year': '',
      });

      // 验证混合值
      expect(record.title, 'Test Movie');
      expect(record.sourceName, '');
      expect(record.cover, 'https://example.com/cover.jpg');
      expect(record.index, 5);
      expect(record.totalEpisodes, 0);
      expect(record.playTime, 120);
      expect(record.totalTime, 0);
      expect(record.saveTime, 1620000000);
      expect(record.year, '');
    });

    test('should handle API response data format', () {
      // 模拟实际API响应数据
      final apiData = {
        "title": "我的个神啊",
        "source_name": "如意资源",
        "cover":
            "https://ry-pic.com/upload/vod/20240913-1/000c4d99384bdef3d248b2b7cb8bf665.jpg",
        "year": "2015",
        "index": 1,
        "total_episodes": 1,
        "play_time": 149,
        "total_time": 9160,
        "save_time": 1757506227611,
      };

      final record = PlayRecordModel.fromJson(apiData);

      expect(record.title, '我的个神啊');
      expect(record.sourceName, '如意资源');
      expect(record.cover,
          'https://ry-pic.com/upload/vod/20240913-1/000c4d99384bdef3d248b2b7cb8bf665.jpg');
      expect(record.year, '2015');
      expect(record.index, 1);
      expect(record.totalEpisodes, 1);
      expect(record.playTime, 149);
      expect(record.totalTime, 9160);
      expect(record.saveTime, 1757506227611);
    });
  });
}
