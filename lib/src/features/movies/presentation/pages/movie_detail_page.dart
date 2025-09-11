import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_event.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_state.dart';
import 'package:mtv_app/src/features/movies/presentation/widgets/authenticated_image.dart';
import 'package:mtv_app/src/features/movies/presentation/pages/video_player_page.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/search_videos.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_popular_movies.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_douban_movies.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_douban_categories.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_video_sources.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_video_detail.dart';
import 'package:mtv_app/src/features/movies/data/repositories/movie_repository_impl.dart';
import 'package:mtv_app/src/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_bloc.dart';
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_event.dart'
    as favorite_event;
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_state.dart';
import 'package:mtv_app/src/features/favorites/domain/entities/favorite.dart';

class MovieDetailPage extends StatefulWidget {
  final String? source;
  final String? id;
  final String? title;
  final String? poster;
  final List<Video>? videoSources; // 添加视频源参数
  final int? selectedSourceIndex; // 添加选中的源索引参数

  const MovieDetailPage({
    super.key,
    this.source,
    this.id,
    required this.title,
    this.poster,
    this.videoSources,
    this.selectedSourceIndex,
  });

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  MovieBloc? _movieBloc;
  FavoriteBloc? _favoriteBloc;
  bool _isInitialized = false;
  List<Video> _videoSources = [];
  Video? _selectedVideo;
  bool _dataLoaded = false; // 标记数据是否已加载
  bool _isFavorite = false; // 标记是否已收藏

  @override
  void initState() {
    super.initState();
    // 如果有传入的视频源数据，直接使用
    if (widget.videoSources != null && widget.videoSources!.isNotEmpty) {
      _videoSources = widget.videoSources!;
      _selectedVideo = _videoSources[widget.selectedSourceIndex ?? 0];
      _dataLoaded = true;
    }
    _initializeBloc();
  }

  Future<void> _initializeBloc() async {
    try {
      // 创建独立的 MovieBloc
      final prefs = await SharedPreferences.getInstance();
      final serverAddress = prefs.getString('api_server_address');

      if (serverAddress != null && mounted) {
        final apiClient = ApiClient(baseUrl: serverAddress);
        final repository = MovieRepositoryImpl(
          remoteDataSource: MovieRemoteDataSourceImpl(apiClient),
        );

        setState(() {
          _movieBloc = MovieBloc(
            getPopularMovies: GetPopularMovies(repository),
            getDoubanMovies: GetDoubanMovies(repository),
            getDoubanCategories: GetDoubanCategories(repository),
            searchVideos: SearchVideos(repository),
            getVideoSources: GetVideoSources(repository),
            getVideoDetail: GetVideoDetail(repository),
          );
          // 获取 FavoriteBloc
          _favoriteBloc = context.read<FavoriteBloc>();
          _isInitialized = true;
        });

        // 只有在数据未加载且没有传入视频源时才搜索视频源
        if (!_dataLoaded && widget.title != null) {
          _movieBloc?.add(SearchVideosEvent(widget.title!));
        }

        // Check favorite status
        if (_selectedVideo != null) {
          final key = '${_selectedVideo!.source ?? 'unknown'}+${_selectedVideo!.id}';
          _favoriteBloc?.add(favorite_event.CheckFavoriteStatus(key));
        }
      } else if (mounted) {
        // 处理无服务器地址的情况
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未配置服务器地址')),
        );
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化失败: $e')),
        );
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _movieBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _movieBloc == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.title ?? '加载中...'),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
          ),
        ),
      );
    }

    return BlocProvider.value(
      value: _movieBloc!,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        body: BlocListener<FavoriteBloc, FavoriteState>(
          listener: (context, state) {
            if (state is FavoriteStatusChecked) {
              setState(() {
                _isFavorite = state.isFavorite;
              });
            }
          },
          child: BlocBuilder<MovieBloc, MovieState>(
            builder: (context, state) {
              // 关键修改：即使在加载状态，如果数据已加载，也要显示内容
              if (state is MovieLoading) {
                if (_dataLoaded) {
                  return _buildVideoDetail();
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orange,
                      strokeWidth: 3,
                    ),
                  );
                }
              } else if (state is VideosLoaded) {
                // 标记数据已加载
                if (!_dataLoaded) {
                  _dataLoaded = true;
                  _videoSources = state.videos;
                  _selectedVideo =
                      _videoSources.isNotEmpty ? _videoSources.first : null;
                  // Check favorite status after video sources are loaded
                  if (_selectedVideo != null) {
                    final key = '${_selectedVideo!.source ?? 'unknown'}+${_selectedVideo!.id}';
                    _favoriteBloc?.add(favorite_event.CheckFavoriteStatus(key));
                  }
                }
                return _buildVideoDetail();
              } else if (state is MovieError) {
                return _buildErrorState(state.message);
              } else {
                // 如果数据已加载，显示内容而不是加载指示器
                if (_dataLoaded) {
                  return _buildVideoDetail();
                } 
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.orange,
                    strokeWidth: 3,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  // 添加收藏/取消收藏的方法
  void _toggleFavorite() {
    if (_selectedVideo == null) return;

    final favorite = Favorite(
      cover: _selectedVideo!.pic ?? '',
      title: _selectedVideo!.title ?? widget.title ?? '未知标题',
      sourceName:
          _selectedVideo!.sourceName ?? _selectedVideo!.source ?? '未知来源',
      totalEpisodes: 1, // 默认 1 集；如有实际集数可替换
      searchTitle: _selectedVideo!.title ?? widget.title ?? '',
      year: _selectedVideo!.year ?? '',
      saveTime: DateTime.now().millisecondsSinceEpoch,
    );

    final key = '${_selectedVideo!.source ?? 'unknown'}+${_selectedVideo!.id}';

    if (_isFavorite) {
      // 取消收藏
      _favoriteBloc?.add(favorite_event.DeleteFavorite(key));
      setState(() {
        _isFavorite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已取消收藏')),
      );
    } else {
      // 添加收藏
      _favoriteBloc?.add(favorite_event.AddFavorite(key, favorite));
      setState(() {
        _isFavorite = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加到收藏')),
      );
    }
  }

  Widget _buildVideoDetail() {
    if (_selectedVideo == null) {
      return const Center(
        child: Text(
          '未找到播放源',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部海报
          SizedBox(
            height: 400,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 背景图片
                if (_selectedVideo?.pic != null &&
                    _selectedVideo!.pic!.isNotEmpty)
                  AuthenticatedImage(
                    imageUrl: _selectedVideo!.pic!,
                    fit: BoxFit.cover,
                  )
                else if (widget.poster != null && widget.poster!.isNotEmpty)
                  AuthenticatedImage(
                    imageUrl: widget.poster!,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    color: Colors.grey[900],
                    child: const Icon(
                      Icons.movie,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                // 渐变遮罩
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black54,
                        Colors.black87,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 内容区域
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  widget.title ?? _selectedVideo?.title ?? '未知标题',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // 基本信息
                Row(
                  children: [
                    if (_selectedVideo?.year != null &&
                        _selectedVideo!.year!.isNotEmpty) ...[
                      Text(
                        _selectedVideo!.year!,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (_selectedVideo?.type != null &&
                        _selectedVideo!.type!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedVideo!.type!,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (_selectedVideo?.note != null &&
                        _selectedVideo!.note!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedVideo!.note!,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // 播放按钮
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_videoSources.isNotEmpty) {
                        _showEpisodeSelector(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('暂无播放源')),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      _videoSources.isNotEmpty
                          ? '播放 (${_selectedVideo?.sourceName ?? _selectedVideo?.source ?? "未知来源"})'
                          : '播放',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 剧情简介 - 使用第一个播放源的desc
                if (_selectedVideo?.description != null &&
                    _selectedVideo!.description!.isNotEmpty) ...[
                  Text(
                    '剧情简介',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedVideo!.description!,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
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
            '加载失败',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (widget.title != null) {
                _movieBloc?.add(SearchVideosEvent(widget.title!));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _showEpisodeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: Colors.orange,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  '选择播放源',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _videoSources.length,
                itemBuilder: (context, index) {
                  final source = _videoSources[index];
                  final isSelected = source.id == _selectedVideo?.id;
                  return Card(
                    color: isSelected
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.grey[800],
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isSelected ? Colors.orange : Colors.grey[600],
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        source.sourceName ?? source.source ?? '未知源${index + 1}',
                        style: TextStyle(
                          color: isSelected ? Colors.orange : Colors.white,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: source.note != null && source.note!.isNotEmpty
                          ? Text(
                              '分类: ${source.note!}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            )
                          : Text(
                              '播放源 ${index + 1}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                      trailing: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.play_arrow,
                        color: Colors.orange,
                      ),
                      onTap: () {
                        // 首先切换选中的播放源
                        setState(() {
                          _selectedVideo = source;
                        });
                        Navigator.pop(context);
                        _playVideo(source, index);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '取消',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playVideo(Video source, int index) {
    // 导航到视频播放页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _movieBloc!,
          child: VideoPlayerPage(
            videoSource: source.source ?? 'unknown',
            videoId: source.id,
            title: source.title ?? widget.title ?? '未知标题',
            videoSources: _videoSources,
            selectedSourceIndex: index,
          ),
        ),
      ),
    );
  }
}
