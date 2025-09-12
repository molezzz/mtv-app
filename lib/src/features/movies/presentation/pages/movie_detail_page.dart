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
import 'package:mtv_app/src/features/favorites/domain/usecases/get_favorites.dart';
import 'package:mtv_app/src/features/favorites/domain/usecases/delete_favorite.dart'
    as delete_usecase;
import 'package:mtv_app/src/features/favorites/domain/usecases/add_favorite.dart'
    as add_usecase;
import 'package:mtv_app/src/features/favorites/domain/usecases/get_favorite_status.dart';
import 'package:mtv_app/src/features/favorites/data/repositories/favorite_repository_impl.dart';
import 'package:mtv_app/src/features/favorites/data/datasources/favorite_remote_data_source.dart';
import 'package:mtv_app/src/features/favorites/domain/entities/favorite.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';
import 'dart:async';

// 定义一个回调函数类型，用于通知收藏状态变化
typedef FavoriteStatusCallback = void Function(String key, bool isFavorite);

class MovieDetailPage extends StatefulWidget {
  final String? source;
  final String? id;
  final String? title;
  final String? poster;
  final List<Video>? videoSources; // 添加视频源参数
  final int? selectedSourceIndex; // 添加选中的源索引参数
  final FavoriteStatusCallback? onFavoriteStatusChanged; // 添加收藏状态变化回调

  const MovieDetailPage({
    super.key,
    this.source,
    this.id,
    required this.title,
    this.poster,
    this.videoSources,
    this.selectedSourceIndex,
    this.onFavoriteStatusChanged,
  });

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  MovieBloc? _movieBloc;
  FavoriteBloc? _favoriteBloc; // 详情页专用的FavoriteBloc实例
  bool _isInitialized = false;
  List<Video> _videoSources = [];
  Video? _selectedVideo;
  bool _dataLoaded = false; // 标记数据是否已加载
  bool _isFavorite = false; // 标记是否已收藏

  // 添加分辨率信息相关的字段
  final Map<String, VideoResolutionInfo> _resolutionInfoMap =
      {}; // 存储每个视频源的分辨率信息
  String? _highestQuality; // 存储所有播放源中的最高分辨率

  @override
  void initState() {
    super.initState();
    print('MovieDetailPage initState 开始');
    // 如果有传入的视频源数据，直接使用
    if (widget.videoSources != null && widget.videoSources!.isNotEmpty) {
      print('使用传入的视频源数据，数量: ${widget.videoSources!.length}');
      _videoSources = widget.videoSources!;
      _selectedVideo = _videoSources[widget.selectedSourceIndex ?? 0];
      _dataLoaded = true;
      // 添加分辨率检测
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('调用 _detectVideoResolutions');
        _detectVideoResolutions();
      });
    } else {
      print('没有传入视频源数据');
    }
    print('MovieDetailPage initState 结束');
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

        // 创建详情页专用的FavoriteBloc实例
        final favoriteRemoteDataSource =
            FavoriteRemoteDataSourceImpl(apiClient);
        final favoriteRepository =
            FavoriteRepositoryImpl(remoteDataSource: favoriteRemoteDataSource);
        final favoriteBloc = FavoriteBloc(
          getFavorites: GetFavorites(favoriteRepository),
          deleteFavorite: delete_usecase.DeleteFavorite(favoriteRepository),
          addFavorite: add_usecase.AddFavorite(favoriteRepository),
          getFavoriteStatus: GetFavoriteStatus(favoriteRepository),
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
          // 使用详情页专用的FavoriteBloc实例
          _favoriteBloc = favoriteBloc;
          _isInitialized = true;
        });

        // 只有在数据未加载且没有传入视频源时才搜索视频源
        if (!_dataLoaded && widget.title != null) {
          _movieBloc?.add(SearchVideosEvent(widget.title!));
        }

        // Check favorite status
        if (_selectedVideo != null) {
          final key =
              '${_selectedVideo!.source ?? 'unknown'}+${_selectedVideo!.id}';
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
    _favoriteBloc?.close(); // 关闭详情页专用的FavoriteBloc实例
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _movieBloc == null || _favoriteBloc == null) {
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

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _movieBloc!),
        BlocProvider.value(value: _favoriteBloc!),
      ],
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
            } else if (state is FavoriteError) {
              // 显示错误信息但不改变当前的收藏状态
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('操作失败: ${state.message}')),
              );
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
                    final key =
                        '${_selectedVideo!.source ?? 'unknown'}+${_selectedVideo!.id}';
                    context
                        .read<FavoriteBloc>()
                        .add(favorite_event.CheckFavoriteStatus(key));
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

  void _handleMovieState(MovieState state) {
    if (state is VideoSourcesLoaded) {
      setState(() {
        print('处理 VideoSourcesLoaded 状态，sources 数量: ${state.sources.length}');
        // 从sources数据创建Video对象列表
        _videoSources = state.sources.map((sourceMap) {
          return Video(
            id: sourceMap['id']?.toString() ?? '',
            title: sourceMap['title']?.toString() ?? '',
            description: sourceMap['description']?.toString(),
            pic: sourceMap['pic']?.toString(),
            year: sourceMap['year']?.toString(),
            note: sourceMap['note']?.toString(),
            type: sourceMap['type']?.toString(),
            source: sourceMap['source']?.toString(),
            sourceName: sourceMap['sourceName']?.toString(),
          );
        }).toList();

        print('创建的 Video 对象数量: ${_videoSources.length}');
        if (_videoSources.isNotEmpty) {
          _selectedVideo = _videoSources[0];
        }
        _dataLoaded = true;
      });

      // 添加分辨率检测
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('调用 _detectVideoResolutions');
        _detectVideoResolutions();
      });
    } else if (state is MovieError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: ${state.message}')),
        );
      }
    }
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

    // 恢复使用完整的key（包含"+"号）
    final key = '${_selectedVideo!.source ?? 'unknown'}+${_selectedVideo!.id}';

    if (_isFavorite) {
      // 取消收藏
      context.read<FavoriteBloc>().add(favorite_event.DeleteFavorite(key));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已取消收藏')),
      );
      // 通知收藏状态变化
      widget.onFavoriteStatusChanged?.call(key, false);
    } else {
      // 添加收藏
      context
          .read<FavoriteBloc>()
          .add(favorite_event.AddFavorite(key, favorite));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加到收藏')),
      );
      // 通知收藏状态变化
      widget.onFavoriteStatusChanged?.call(key, true);
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
            // 显示最高分辨率
            if (_highestQuality != null && _highestQuality != 'N/A')
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '最高画质: $_highestQuality',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _videoSources.length,
                itemBuilder: (context, index) {
                  final source = _videoSources[index];
                  final isSelected = source.id == _selectedVideo?.id;
                  // 获取该源的分辨率信息，使用源ID作为键
                  final resolutionInfo = _resolutionInfoMap[source.id];

                  print(
                      '显示播放源: index=$index, source=${source.source}, resolutionInfo=$resolutionInfo');

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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (source.note != null && source.note!.isNotEmpty)
                            Text(
                              '分类: ${source.note!}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            )
                          else
                            Text(
                              '播放源 ${index + 1}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          // 显示分辨率信息
                          if (resolutionInfo != null &&
                              resolutionInfo.quality != 'N/A')
                            Row(
                              children: [
                                // 分辨率标签
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  margin:
                                      const EdgeInsets.only(top: 4, right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    resolutionInfo.quality,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // 速度标签
                                if (resolutionInfo.loadSpeed != 'N/A')
                                  Text(
                                    resolutionInfo.loadSpeed,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                // 延迟标签
                                const SizedBox(width: 8),
                                Text(
                                  '${resolutionInfo.pingTime}ms',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                        ],
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

                        // 检查新选中视频的收藏状态
                        final key =
                            '${source.source ?? 'unknown'}+${source.id}';
                        _favoriteBloc
                            ?.add(favorite_event.CheckFavoriteStatus(key));

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

  /// 检测所有视频源的分辨率信息
  Future<void> _detectVideoResolutions() async {
    print('=== 开始检测视频源分辨率 ===');
    print('视频源数量: ${_videoSources.length}');

    if (_videoSources.isEmpty) {
      print('视频源为空，跳过检测');
      return;
    }

    try {
      // 为每个视频源获取详细信息并提取第一集URL进行分辨率检测
      final Map<String, String> sourceUrls = {}; // 存储源ID到第一集URL的映射
      final Map<String, String> sourceIds = {}; // 存储URL到源ID的映射

      // 并行获取所有视频源的详细信息
      final List<Future<void>> detailFutures = [];
      for (int i = 0; i < _videoSources.length; i++) {
        final source = _videoSources[i];
        print('检查视频源 $i: id=${source.id}, source=${source.source}');
        if (source.source != null &&
            source.source!.isNotEmpty &&
            source.id.isNotEmpty) {
          final future =
              _getVideoDetailForResolution(source.source!, source.id, i)
                  .then((url) {
            if (url != null) {
              sourceUrls[source.id] = url; // 使用source.id作为键
              sourceIds[url] = source.id; // 建立URL到源ID的映射
              print('获取到源${source.source}的视频URL: $url');
            } else {
              print('源${source.source}没有返回有效的视频URL');
            }
          }).catchError((e) {
            print('获取源${source.source}的视频详情失败: $e');
          });
          detailFutures.add(future);
        } else {
          print('跳过无效视频源: index=$i, id=${source.id}, source=${source.source}');
        }
      }

      // 等待所有详细信息获取完成
      print('等待所有视频详情获取完成，任务数量: ${detailFutures.length}');
      await Future.wait(detailFutures);
      print('所有视频详情获取完成');

      // 打印映射信息用于调试
      print('sourceUrls映射: $sourceUrls');
      print('sourceIds映射: $sourceIds');

      if (sourceUrls.isEmpty) {
        print('没有获取到任何有效的视频URL，跳过检测');
        return;
      }

      // 提取URL列表进行分辨率检测
      final List<String> urls = sourceUrls.values.toList();

      // 批量获取分辨率信息
      print('开始批量获取分辨率信息，URL数量: ${urls.length}');
      print('URL列表: $urls');

      final resolutionMap =
          await VideoResolutionDetector.getVideoResolutionsFromM3u8List(urls);
      print('分辨率信息获取完成，结果数量: ${resolutionMap.length}');
      print('分辨率映射: $resolutionMap');

      // 更新分辨率信息映射
      String? highestQuality;

      // 遍历源ID到URL的映射
      sourceUrls.forEach((sourceId, url) {
        print('处理结果: sourceId=$sourceId, url=$url');

        if (resolutionMap.containsKey(url)) {
          final resolutionInfo = resolutionMap[url]!;
          print('设置分辨率信息: sourceId=$sourceId, url=$url, info=$resolutionInfo');
          setState(() {
            // 使用sourceId作为键存储分辨率信息，与_showEpisodeSelector中使用的键保持一致
            _resolutionInfoMap[sourceId] = resolutionInfo;
          });

          // 更新最高分辨率
          final quality = resolutionInfo.quality;
          print('当前质量: $quality');

          if (highestQuality == null && quality != 'N/A') {
            highestQuality = quality;
            print('设置初始最高质量: $highestQuality');
          } else if (quality != 'N/A' && highestQuality != null) {
            // 根据分辨率等级确定最高质量
            final currentRank = _getQualityRank(highestQuality!); // 添加感叹号确保非空
            final newRank = _getQualityRank(quality);
            print(
                '质量等级比较: $highestQuality($currentRank) vs $quality($newRank)');

            if (newRank > currentRank) {
              highestQuality = quality;
              print('更新最高质量: $highestQuality');
            }
          } else if (quality != 'N/A' && highestQuality == null) {
            highestQuality = quality;
            print('设置最高质量: $highestQuality');
          }
        } else {
          print('未找到URL的分辨率信息: url=$url');
        }
      });

      // 更新最高分辨率
      if (highestQuality != null) {
        print('最终最高分辨率: $highestQuality');
        setState(() {
          _highestQuality = highestQuality;
        });
      } else {
        print('没有检测到有效的最高分辨率');
      }

      print('=== 视频源分辨率检测完成 ===');
    } catch (e, stackTrace) {
      print('检测视频分辨率时出错: $e');
      print('错误堆栈: $stackTrace');
    }
  }

  /// 获取视频详情并提取第一集URL用于分辨率检测
  Future<String?> _getVideoDetailForResolution(
      String source, String id, int index) async {
    print('获取视频详情用于分辨率检测: source=$source, id=$id, index=$index');
    try {
      // 创建临时的MovieBloc用于获取视频详情
      final prefs = await SharedPreferences.getInstance();
      final serverAddress = prefs.getString('api_server_address');

      if (serverAddress == null) {
        print('服务器地址为空');
        return null;
      }

      print('使用服务器地址: $serverAddress');
      final apiClient = ApiClient(baseUrl: serverAddress);
      final repository = MovieRepositoryImpl(
        remoteDataSource: MovieRemoteDataSourceImpl(apiClient),
      );

      print('开始获取视频详情: source=$source, id=$id');
      // 添加更多的错误处理和调试信息
      try {
        final videoDetail = await repository.getVideoDetail(source, id);
        print(
            '获取到视频详情: source=$source, id=$id, episodes数量=${videoDetail.episodes?.length ?? 0}');

        // 打印详细的剧集信息
        if (videoDetail.episodes != null) {
          print('剧集列表:');
          for (int i = 0; i < videoDetail.episodes!.length; i++) {
            print('  第${i + 1}集: ${videoDetail.episodes![i]}');
          }
        }

        // 返回第一集URL用于分辨率检测
        if (videoDetail.episodes != null && videoDetail.episodes!.isNotEmpty) {
          final firstEpisodeUrl = videoDetail.episodes!.first;
          print('源$index的第一集URL: $firstEpisodeUrl');
          return firstEpisodeUrl;
        } else {
          print('源$index没有剧集信息');
          return null;
        }
      } catch (e, stackTrace) {
        print('获取视频详情时发生错误: $e');
        print('错误堆栈: $stackTrace');
        // 尝试使用不同的参数格式
        try {
          print('尝试使用不同的参数格式...');
          final videoDetail = await repository.getVideoDetail(source, id);
          print(
              '使用不同参数格式获取到视频详情: source=$source, id=$id, episodes数量=${videoDetail.episodes?.length ?? 0}');
          if (videoDetail.episodes != null &&
              videoDetail.episodes!.isNotEmpty) {
            final firstEpisodeUrl = videoDetail.episodes!.first;
            print('源$index的第一集URL: $firstEpisodeUrl');
            return firstEpisodeUrl;
          }
        } catch (e2) {
          print('使用不同参数格式也失败了: $e2');
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('获取视频详情失败: source=$source, id=$id, 错误: $e');
      print('错误堆栈: $stackTrace');
      return null;
    }
  }

  /// 根据分辨率标签获取等级（数字越大质量越高）
  int _getQualityRank(String quality) {
    switch (quality) {
      case '4K':
        return 5;
      case '2K':
        return 4;
      case '1080p':
        return 3;
      case '720p':
        return 2;
      case '480p':
        return 1;
      default:
        return 0;
    }
  }
}
