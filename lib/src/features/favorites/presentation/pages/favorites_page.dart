import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/l10n/app_localizations.dart';
import 'package:mtv_app/src/core/widgets/language_selector.dart';
import 'package:mtv_app/src/features/settings/presentation/pages/settings_page.dart';
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_bloc.dart';
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_event.dart';
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_state.dart';
import 'package:mtv_app/src/features/favorites/presentation/widgets/favorite_card.dart';
import 'package:mtv_app/src/features/movies/presentation/utils/navigation_helper.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    // 加载收藏列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteBloc>().add(LoadFavorites());
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.favorites ?? 'Favorites'),
        actions: [
          const LanguageSelector(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    onSettingsSaved: () {
                      Navigator.pop(context);
                      // 重新加载收藏列表
                      context.read<FavoriteBloc>().add(LoadFavorites());
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<FavoriteBloc, FavoriteState>(
        builder: (context, state) {
          if (state is FavoriteLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    localizations?.loading ?? 'Loading...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          } else if (state is FavoritesLoaded) {
            if (state.favorites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations?.noRecords ?? 'No records yet',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations?.yourFavoriteContent ??
                          'Your Favorite Content',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 9 / 16, // 9:16比例，适合电影海报
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: state.favorites.length,
              itemBuilder: (context, index) {
                final favorite = state.favorites[index];
                return FavoriteCard(
                  favorite: favorite,
                  onTap: () {
                    // 导航到详情页面
                    NavigationHelper.navigateToMovieDetail(
                      context: context,
                      title: favorite.title,
                      imageUrl: favorite.cover,
                      video: null, // 在实际应用中可能需要传递视频对象
                    );
                  },
                  onDelete: () {
                    // 显示确认对话框
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(localizations?.delete ?? 'Delete'),
                          content: Text(
                              '${localizations?.confirmDelete ?? 'Are you sure you want to delete'} "${favorite.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(localizations?.cancel ?? 'Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // 在实际应用中，这里应该调用删除API
                                // 并重新加载收藏列表
                                context
                                    .read<FavoriteBloc>()
                                    .add(LoadFavorites());
                              },
                              child: Text(localizations?.delete ?? 'Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          } else if (state is FavoriteError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations?.error ?? 'Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<FavoriteBloc>().add(LoadFavorites());
                    },
                    child: Text(localizations?.retry ?? 'Retry'),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations?.favorites ?? 'Favorites',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations?.yourFavoriteContent ??
                        'Your Favorite Content',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations?.loading ?? 'Loading...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
