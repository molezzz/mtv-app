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
    {'name': '热门', 'tag': 'hot_gaia', 'type': 'tv'},
    {'name': '最新', 'tag': 'now_playing', 'type': 'tv'},
    {'name': '高分', 'tag': 'top_gaia', 'type': 'tv'},
    {'name': '国产剧', 'tag': 'domestic', 'type': 'tv'},
    {'name': '美剧', 'tag': 'american', 'type': 'tv'},
    {'name': '韩剧', 'tag': 'korean', 'type': 'tv'},
    {'name': '日剧', 'tag': 'japanese', 'type': 'tv'},
    {'name': '英剧', 'tag': 'british', 'type': 'tv'},
  ];

  // 预定义的综艺分类
  static const List<Map<String, String>> showCategories = [
    {'name': '热门', 'tag': 'hot_gaia', 'type': 'show'},
    {'name': '最新', 'tag': 'now_playing', 'type': 'show'},
    {'name': '高分', 'tag': 'top_gaia', 'type': 'show'},
    {'name': '大陆综艺', 'tag': 'domestic', 'type': 'show'},
    {'name': '港台综艺', 'tag': 'hktw', 'type': 'show'},
    {'name': '日韩综艺', 'tag': 'korean', 'type': 'show'},
    {'name': '欧美综艺', 'tag': 'western', 'type': 'show'},
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
                  onCategorySelected(category['tag']!, category['type']!);
                }
              },
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
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