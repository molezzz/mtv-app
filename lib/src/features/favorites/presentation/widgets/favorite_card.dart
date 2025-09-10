import 'package:flutter/material.dart';
import 'package:mtv_app/src/features/movies/presentation/widgets/authenticated_image.dart';
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_state.dart';

class FavoriteCard extends StatelessWidget {
  final FavoriteItem favorite;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const FavoriteCard({
    super.key,
    required this.favorite,
    required this.onTap,
    required this.onDelete,
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
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  color: Colors.grey[300],
                ),
                child: favorite.cover.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        child: AuthenticatedImage(
                          imageUrl: favorite.cover,
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
            // 收藏信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      favorite.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // 来源和年份
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            favorite.sourceName,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (favorite.year.isNotEmpty) ...[
                          Text(
                            favorite.year,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // 集数和删除按钮
                    Row(
                      children: [
                        Text(
                          '共 ${favorite.totalEpisodes} 集',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 16),
                          onPressed: onDelete,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
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
