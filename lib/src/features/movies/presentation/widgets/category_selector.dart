import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String, String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
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

  static const List<Map<String, String>> tvCategories = [
    {'name': '热门剧集', 'tag': '热门', 'type': 'tv'},
    {'name': '最新剧集', 'tag': '最新', 'type': 'tv'},
    {'name': '综艺', 'tag': '综艺', 'type': 'tv'},
    {'name': '纪录片', 'tag': '纪录片', 'type': 'tv'},
    {'name': '国产剧', 'tag': '国产剧', 'type': 'tv'},
    {'name': '美剧', 'tag': '美剧', 'type': 'tv'},
    {'name': '韩剧', 'tag': '韩剧', 'type': 'tv'},
    {'name': '日剧', 'tag': '日剧', 'type': 'tv'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movieCategories.length,
        itemBuilder: (context, index) {
          final category = movieCategories[index];
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