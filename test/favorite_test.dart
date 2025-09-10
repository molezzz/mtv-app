import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/features/favorites/domain/entities/favorite.dart';

void main() {
  group('Favorite', () {
    test('should create a Favorite instance from JSON', () {
      final json = {
        'cover': 'https://example.com/cover.jpg',
        'title': 'Test Movie',
        'source_name': 'Test Source',
        'total_episodes': 10,
        'search_title': 'test movie',
        'year': '2023',
        'save_time': 1234567890,
      };

      final favorite = Favorite.fromJson(json);

      expect(favorite.cover, 'https://example.com/cover.jpg');
      expect(favorite.title, 'Test Movie');
      expect(favorite.sourceName, 'Test Source');
      expect(favorite.totalEpisodes, 10);
      expect(favorite.searchTitle, 'test movie');
      expect(favorite.year, '2023');
      expect(favorite.saveTime, 1234567890);
    });

    test('should convert Favorite instance to JSON', () {
      final favorite = Favorite(
        cover: 'https://example.com/cover.jpg',
        title: 'Test Movie',
        sourceName: 'Test Source',
        totalEpisodes: 10,
        searchTitle: 'test movie',
        year: '2023',
        saveTime: 1234567890,
      );

      final json = favorite.toJson();

      expect(json['cover'], 'https://example.com/cover.jpg');
      expect(json['title'], 'Test Movie');
      expect(json['source_name'], 'Test Source');
      expect(json['total_episodes'], 10);
      expect(json['search_title'], 'test movie');
      expect(json['year'], '2023');
      expect(json['save_time'], 1234567890);
    });
  });
}
