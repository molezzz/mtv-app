import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_event.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_state.dart';
import 'package:mtv_app/src/features/movies/presentation/widgets/movie_card.dart';
import 'package:mtv_app/src/features/movies/presentation/widgets/category_selector.dart';
import 'package:mtv_app/src/features/movies/presentation/widgets/search_bar.dart'
    as custom;
import 'package:mtv_app/src/features/movies/presentation/utils/navigation_helper.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/l10n/app_localizations.dart';
import 'package:mtv_app/src/features/settings/presentation/pages/settings_page.dart';
import 'package:mtv_app/src/core/widgets/language_selector.dart';

class MediaListPage extends StatefulWidget {
  final String mediaType; // 'movie', 'tv', 'show'
  final String title;
  final String defaultCategory;
  final String categoryType; // 'movie', 'tv', 'show'

  const MediaListPage({
    super.key,
    required this.mediaType,
    required this.title,
    this.defaultCategory = '热门',
    this.categoryType = 'movie',
  });

  @override
  State<MediaListPage> createState() => _MediaListPageState();
}

class _MediaListPageState extends State<MediaListPage> {
  final _scrollController = ScrollController();
  String _selectedCategory = '';
  String _searchQuery = '';
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.defaultCategory;
    _scrollController.addListener(_onScroll);
    _loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent == 0) {
      _loadMore();
    }
  }

  void _loadInitialData() {
    if (widget.mediaType == 'tv') {
      context.read<MovieBloc>().add(
            FetchDoubanCategories(
              kind: 'tv',
              category: 'tv',
              type:
                  _selectedCategory.isEmpty ? 'tv_hot_gaia' : _selectedCategory,
              limit: 25,
              start: 0,
            ),
          );
    } else if (widget.mediaType == 'show') {
      context.read<MovieBloc>().add(
            FetchDoubanCategories(
              kind: 'tv',
              category: 'show',
              type: _selectedCategory.isEmpty
                  ? 'show_hot_gaia'
                  : _selectedCategory,
              limit: 25,
              start: 0,
            ),
          );
    } else {
      context.read<MovieBloc>().add(
            FetchDoubanMovies(
              type: widget.categoryType,
              tag: _selectedCategory,
            ),
          );
    }
  }

  void _onCategorySelected(String category, String type) {
    setState(() {
      _selectedCategory = category;
      _isSearchMode = false;
      _searchQuery = '';
    });

    if (widget.mediaType == 'tv') {
      context.read<MovieBloc>().add(
            FetchDoubanCategories(
              kind: 'tv',
              category: 'tv',
              type: type, // 使用传入的type参数，它已经包含了正确的前缀
              limit: 25,
              start: 0,
            ),
          );
    } else if (widget.mediaType == 'show') {
      context.read<MovieBloc>().add(
            FetchDoubanCategories(
              kind: 'tv',
              category: 'show',
              type: type, // 使用传入的type参数，它已经包含了正确的前缀
              limit: 25,
              start: 0,
            ),
          );
    } else {
      context.read<MovieBloc>().add(
            SelectCategory(
              category: category,
              type: type,
            ),
          );
    }
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearchMode = false;
        _searchQuery = '';
      });
      _loadInitialData();
    } else {
      setState(() {
        _isSearchMode = true;
        _searchQuery = query;
      });
      context.read<MovieBloc>().add(
            SearchVideosEvent(query),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSearchMode ? '搜索结果' : widget.title,
        ),
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
                    },
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              custom.SearchBar(
                onSearch: _onSearch,
                initialQuery: _searchQuery,
              ),
              if (!_isSearchMode)
                CategorySelector(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: _onCategorySelected,
                  type: widget.categoryType,
                ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<MovieBloc, MovieState>(
        builder: (context, state) {
          if (state is MovieLoading && state is! DoubanMoviesLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.loading ?? 'Loading...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          } else if (state is DoubanMoviesLoaded) {
            print('DoubanMoviesLoaded hasReachedMax: ${state.hasReachedMax}');
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
            return _buildMovieGrid(
              movies: state.movies
                  .map((movie) => _MovieDisplayItem(
                        title: movie.title,
                        imageUrl: movie.pic,
                        year: movie.year,
                        description: '', // 豆瓣电影通常没有描述
                        rating: movie.rating,
                      ))
                  .toList(),
              hasReachedMax: state.hasReachedMax,
            );
          } else if (state is VideosLoaded) {
            return _buildMovieGrid(
              movies: state.videos
                  .map((video) => _MovieDisplayItem(
                        title: video.title,
                        imageUrl: video.pic,
                        year: video.year,
                        description: video.description ?? '',
                        rating: null,
                      ))
                  .toList(),
            );
          } else if (state is MovieLoaded) {
            return _buildMovieGrid(
              movies: state.movies
                  .map((movie) => _MovieDisplayItem(
                        title: movie.title,
                        imageUrl: movie.posterPath,
                        year: '', // TMDB movies don't have year in this entity
                        description: movie.overview,
                        rating: null,
                      ))
                  .toList(),
            );
          } else if (state is MovieError) {
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
                    AppLocalizations.of(context)?.error ?? 'Error',
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
                      if (_isSearchMode && _searchQuery.isNotEmpty) {
                        context
                            .read<MovieBloc>()
                            .add(SearchVideosEvent(_searchQuery));
                      } else {
                        _loadInitialData();
                      }
                    },
                    child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
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
                    Icons.movie,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.loading ?? 'Loading...',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildMovieGrid(
      {required List<_MovieDisplayItem> movies, bool hasReachedMax = true}) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearchMode ? '没有找到相关内容' : '暂无数据',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearchMode ? '尝试搜索其他关键词' : '请稍后再试',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 9 / 16, // 9:16比例，适合电影海报
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: hasReachedMax ? movies.length : movies.length + 1,
        itemBuilder: (context, index) {
          if (index >= movies.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final movie = movies[index];
          return MovieCard(
            title: movie.title,
            imageUrl: movie.imageUrl,
            year: movie.year,
            description: movie.description,
            rating: movie.rating,
            onTap: () {
              final currentState = context.read<MovieBloc>().state;
              Video? videoSource;

              if (currentState is VideosLoaded) {
                try {
                  videoSource = currentState.videos.firstWhere(
                    (v) => v.title == movie.title,
                  );
                } catch (e) {
                  videoSource = null;
                }
              }

              NavigationHelper.navigateToMovieDetail(
                context: context,
                title: movie.title,
                imageUrl: movie.imageUrl,
                video: videoSource,
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      _loadMore();
    }
  }

  void _loadMore() {
    final state = context.read<MovieBloc>().state;
    if (state is DoubanMoviesLoaded && !state.hasReachedMax) {
      print('Loading more movies...');
      if (widget.mediaType == 'tv') {
        context.read<MovieBloc>().add(FetchMoreDoubanCategories(
              kind: 'tv',
              category: 'tv',
              type:
                  _selectedCategory.isEmpty ? 'tv_hot_gaia' : _selectedCategory,
              start: state.movies.length,
            ));
      } else if (widget.mediaType == 'show') {
        context.read<MovieBloc>().add(FetchMoreDoubanCategories(
              kind: 'tv',
              category: 'show',
              type: _selectedCategory.isEmpty
                  ? 'show_hot_gaia'
                  : _selectedCategory,
              start: state.movies.length,
            ));
      } else {
        context.read<MovieBloc>().add(FetchMoreDoubanMovies(
              type: widget.categoryType,
              tag: _selectedCategory,
              pageStart: state.movies.length,
            ));
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _refreshData() async {
    if (_isSearchMode && _searchQuery.isNotEmpty) {
      context.read<MovieBloc>().add(SearchVideosEvent(_searchQuery));
    } else {
      _loadInitialData();
    }
  }
}

class _MovieDisplayItem {
  final String title;
  final String? imageUrl;
  final String? year;
  final String? description;
  final double? rating;

  const _MovieDisplayItem({
    required this.title,
    this.imageUrl,
    this.year,
    this.description,
    this.rating,
  });
}
