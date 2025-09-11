import 'package:flutter_test/flutter_test.dart';
import 'package:mtv_app/src/features/movies/presentation/widgets/category_selector.dart';

void main() {
  group('CategorySelector Tests', () {
    test('TV Categories should have correct tags', () {
      // 验证剧集分类标签是否正确
      expect(CategorySelector.tvCategories[0]['type'], 'tv_hot_gaia');
      expect(CategorySelector.tvCategories[1]['type'], 'tv_now_playing');
      expect(CategorySelector.tvCategories[2]['type'], 'tv_top_gaia');
      expect(CategorySelector.tvCategories[3]['type'], 'tv_domestic');
      expect(CategorySelector.tvCategories[4]['type'], 'tv_american');
      expect(CategorySelector.tvCategories[5]['type'], 'tv_korean');
      expect(CategorySelector.tvCategories[6]['type'], 'tv_japanese');
      expect(CategorySelector.tvCategories[7]['type'], 'tv_british');
    });

    test('Show Categories should have correct tags', () {
      // 验证综艺分类标签是否正确
      expect(CategorySelector.showCategories[0]['type'], 'show_hot_gaia');
      expect(CategorySelector.showCategories[1]['type'], 'show_now_playing');
      expect(CategorySelector.showCategories[2]['type'], 'show_top_gaia');
      expect(CategorySelector.showCategories[3]['type'], 'show_domestic');
      expect(CategorySelector.showCategories[4]['type'], 'show_hktw');
      expect(CategorySelector.showCategories[5]['type'], 'show_korean');
      expect(CategorySelector.showCategories[6]['type'], 'show_western');
    });

    test('TV Categories should have correct prefix', () {
      // 验证剧集分类标签是否都包含tv_前缀
      for (var category in CategorySelector.tvCategories) {
        expect(category['type'], startsWith('tv_'));
      }
    });

    test('Show Categories should have correct prefix', () {
      // 验证综艺分类标签是否都包含show_前缀
      for (var category in CategorySelector.showCategories) {
        expect(category['type'], startsWith('show_'));
      }
    });
  });
}
