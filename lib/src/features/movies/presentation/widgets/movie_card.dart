import 'package:flutter/material.dart';
import 'authenticated_image.dart';

class MovieCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? year;
  final String? description;
  final double? rating;
  final VoidCallback? onTap;

  const MovieCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.year,
    this.description,
    this.rating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 海报图片
            Expanded(
              flex: 5, // 增加海报所占比例，适配9:16比例
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  color: Colors.grey[300],
                ),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        child: AuthenticatedImage(
                          imageUrl: imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.movie,
                        size: 48,
                        color: Colors.grey,
                      ),
              ),
            ),
            // 电影信息
            Expanded(
              flex: 1, // 减少信息区域的比例，给海报更多空间
              child: Padding(
                padding: const EdgeInsets.all(6.0), // 减小内边距
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1, // 只显示一行标题
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // 减小间距
                    // 年份和评分
                    Row(
                      children: [
                        if (year != null && year!.isNotEmpty) ...[
                          Text(
                            year!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                        const Spacer(),
                        if (rating != null && rating! > 0) ...[
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
