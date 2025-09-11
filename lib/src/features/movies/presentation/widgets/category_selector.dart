import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String, String) onCategorySelected;
  final String type; // 新增type参数

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.type = 'movie', // 默认为电影类型
  });

  // 预定义的电影分类
  static const List<Map<String, String>> movieCategories = [
    {'name': '热门', 'tag': '热门', 'type': 'movie'},
    {'name': '最新', 'tag': '最新', 'type': 'movie'},
    {'name': 'Top250', 'tag': 'top250', 'type': 'movie'},
    {'name': '科幻', 'tag': '科幻', 'type': 'movie'},
    {'name': '喜剧', 'tag': '喜剧', 'type': 'movie'},
    {'name': '动作', 'tag': '动作', 'type': 'movie'},
    {'name': '爱情', 'tag': '爱情', 'type': 'movie'},
    {'name': '恐怖', 'tag': '恐怖', 'type': 'movie'},
    {'name': '剧情', 'tag': '剧情', 'type': 'movie'},
    {'name': '动画', 'tag': '动画', 'type': 'movie'},
  ];

  // 预定义的剧集分类
  static const List<Map<String, String>> tvCategories = [
    {'name': '全部', 'tag': 'all', 'type': 'tv'},
    {'name': '国产剧', 'tag': 'domestic', 'type': 'tv_domestic'},
    {'name': '美剧', 'tag': 'american', 'type': 'tv_american'},
    {'name': '韩剧', 'tag': 'korean', 'type': 'tv_korean'},
    {'name': '日剧', 'tag': 'japanese', 'type': 'tv_japanese'},
    {'name': '动漫', 'tag': 'animation', 'type': 'tv_animation'},
    {'name': '纪录片', 'tag': 'documentary', 'type': 'tv_documentary'},
  ];

  // 预定义的综艺分类
  static const List<Map<String, String>> showCategories = [
    {'name': '全部', 'tag': 'all', 'type': 'show'},
    {'name': '国内', 'tag': 'domestic', 'type': 'show_domestic'},
    {'name': '国外', 'tag': 'foreign', 'type': 'show_foreign'},
  ];

  @override
  Widget build(BuildContext context) {
    // 根据type选择分类列表
    List<Map<String, String>> categories;
    if (type == 'tv') {
      categories = tvCategories;
    } else if (type == 'show') {
      categories = showCategories;
    } else {
      categories = movieCategories;
    }

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['tag'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category['name']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  // 传递tag和type参数，其中type应该包含完整前缀
                  onCategorySelected(category['tag']!, category['type']!);
                }
              },
              selectedColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}
