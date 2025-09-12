import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_event.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_state.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video_detail.dart';
import 'package:mtv_app/src/core/services/cast_service.dart';
import 'package:mtv_app/src/features/movies/presentation/widgets/cast_device_selector.dart';
import 'package:mtv_app/src/features/movies/presentation/pages/cast_control_page.dart';
import 'package:mtv_app/src/features/movies/presentation/widgets/video_player_widget.dart';
import 'package:mtv_app/src/features/movies/data/models/play_record_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:mtv_app/src/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoSource;
  final String videoId;
  final String? episodeUrl;
  final String title;
  final List<Video>? videoSources;
  final int? selectedSourceIndex;
  final VoidCallback? onVideoEnded; // 添加视频结束回调
  final int? initialPlayTime; // 添加初始播放时间参数

  const VideoPlayerPage({
    super.key,
    required this.videoSource,
    required this.videoId,
    this.episodeUrl,
    required this.title,
    this.videoSources,
    this.selectedSourceIndex,
    this.onVideoEnded,
    this.initialPlayTime, // 添加初始播放时间参数
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  final CustomVideoPlayerController _playerController =
      CustomVideoPlayerController();
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  VideoDetail? _videoDetail;
  List<String> _episodes = [];
  int _currentEpisodeIndex = 0;
  double _currentPlaybackSpeed = 1.0;
  List<Video>? _videoSources;
  int _currentSourceIndex = 0;
  bool _isControlsVisible = true;
  bool _isCasting = false;
  String? _currentVideoUrl;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isFullScreen = true; // 默认全屏
  double _volume = 1.0; // 默认音量
  Timer? _hideControlsTimer; // 控制栏自动隐藏计时器
  bool _isSeeking = false; // 是否正在拖动进度条
  bool _isBuffering = false; // 是否正在缓冲
  Duration? _seekTarget; // 期望跳转到的目标位置
  Duration? _dragPosition; // UI层当前拖动的位置
  late MovieRemoteDataSource _dataSource; // 用于保存播放记录
  Timer? _playRecordTimer; // 定时保存播放记录
  bool _hasSeekedToInitialPosition = false; // 是否已经跳转到初始位置

  // 添加分辨率信息映射
  final Map<int, VideoResolutionInfo> _resolutionInfoMap = {};

  final List<double> _playbackSpeeds = [0.5, 1.0, 2.0];

  @override
  void initState() {
    super.initState();
    print('VideoPlayerPage initState 开始');
    _videoSources = widget.videoSources;
    _currentSourceIndex = widget.selectedSourceIndex ?? 0;
    _initializeVideoPlayer();
    _setScreenToLandscape();
    WakelockPlus.enable(); // 保持屏幕常亮
    _checkCastingStatus();
    _initializeDataSource(); // 初始化数据源
    print('调用 _detectVideoResolutions');
    _detectVideoResolutions(); // 添加这一行，检测视频源分辨率
    print('VideoPlayerPage initState 结束');
  }

  @override
  void dispose() {
    _disposeControllers();
    _hideControlsTimer?.cancel(); // 取消计时器
    _playRecordTimer?.cancel(); // 取消播放记录定时器
    _savePlayRecord(); // 页面销毁前保存一次播放记录
    _setScreenToPortrait();
    WakelockPlus.disable(); // 恢复屏幕锁定
    // 只在移动平台停止设备发现
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      CastService.stopDiscovery();
    }
    super.dispose();
  }

  void _initializeDataSource() async {
    final prefs = await SharedPreferences.getInstance();
    // 修复：使用正确的键名 'api_server_address' 而不是 'server_url'
    final serverUrl =
        prefs.getString('api_server_address') ?? 'http://localhost:3000';
    final apiClient = ApiClient(baseUrl: serverUrl);
    _dataSource = MovieRemoteDataSourceImpl(apiClient);
  }

  void _setScreenToLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _setScreenToPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _disposeControllers() {
    // FPlayer会在VideoPlayerWidget的dispose方法中自动销毁
  }

  // 控制栏显示/隐藏方法
  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
    _resetHideControlsTimer();
  }

  void _showControls() {
    setState(() {
      _isControlsVisible = true;
    });
    _resetHideControlsTimer();
  }

  void _hideControls() {
    setState(() {
      _isControlsVisible = false;
    });
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_isControlsVisible) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _hideControls();
        }
      });
    }
  }

  // 播放控制方法
  void _togglePlayPause() {
    if (_isPlaying) {
      _playerController.pause();
    } else {
      _playerController.play();
    }
    _showControls();
  }

  void _onSeekChanged(double value) {
    final newPosition =
        Duration(milliseconds: (value * _duration.inMilliseconds).round());

    // 拖动时只更新UI拖动位置，避免被真实播放位置覆盖
    setState(() {
      _dragPosition = newPosition;
    });
    _showControls();
  }

  void _onSeekStart(double value) {
    // 开始拖动时设置拖动状态并显示控制栏
    final startPosition =
        Duration(milliseconds: (value * _duration.inMilliseconds).round());
    setState(() {
      _isSeeking = true;
      _seekTarget = null;
      _dragPosition = startPosition;
    });
    _showControls();
  }

  void _onSeekEnd(double value) {
    // 拖动结束时执行实际的跳转
    final newPosition =
        Duration(milliseconds: (value * _duration.inMilliseconds).round());

    setState(() {
      _isBuffering = true; // 显示缓冲状态
      _seekTarget = newPosition; // 记录目标位置
      _dragPosition = newPosition; // 松手时保持UI位置
    });

    _playerController.seekTo(newPosition);

    // 不要立即将 _isSeeking 置为 false，等待位置接近目标后再清除
    _resetHideControlsTimer();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      _setScreenToLandscape();
    } else {
      _setScreenToPortrait();
    }
    _showControls();
  }

  void _adjustVolume(double delta) {
    setState(() {
      _volume = (_volume + delta).clamp(0.0, 1.0);
    });
    _playerController.setVolume(_volume);
    _showControls();
  }

  Future<void> _checkCastingStatus() async {
    try {
      // 只在移动平台检查投屏状态
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final isConnected = await CastService.isConnected();
        setState(() {
          _isCasting = isConnected;
        });
      } else {
        // 桌面平台暂不支持投屏
        setState(() {
          _isCasting = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking casting status: $e');
      setState(() {
        _isCasting = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // 首先获取视频详情
      await _fetchVideoDetail();

      // 如果有传入特定的episodeUrl，直接使用
      if (widget.episodeUrl != null && widget.episodeUrl!.isNotEmpty) {
        await _playVideoFromUrl(widget.episodeUrl!);
      } else if (_episodes.isNotEmpty) {
        // 否则播放第一集
        await _playVideoFromUrl(_episodes[0]);
      } else {
        throw Exception('没有可播放的内容');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchVideoDetail() async {
    final currentSource = _videoSources != null && _videoSources!.isNotEmpty
        ? _videoSources![_currentSourceIndex]
        : null;

    print('\n=== 获取视频详情调试 ===');
    print('当前选中的源索引: $_currentSourceIndex');
    print('源总数量: ${_videoSources?.length ?? 0}');
    print('当前源信息: $currentSource');
    print('Widget传入参数:');
    print('  - videoSource: ${widget.videoSource}');
    print('  - videoId: ${widget.videoId}');
    print('  - episodeUrl: ${widget.episodeUrl}');
    print('===========================\n');

    if (currentSource != null) {
      // 使用当前选中的视频源信息
      final source = currentSource.source ?? widget.videoSource;
      final id = currentSource.id;
      print('使用当前源信息: source=$source, id=$id');

      context.read<MovieBloc>().add(
            GetVideoDetailEvent(source, id),
          );

      // 监听状态变化
      await for (final state in context.read<MovieBloc>().stream) {
        if (state is VideoDetailLoaded) {
          print('\n=== 视频详情加载成功 ===');
          print('视频标题: ${state.videoDetail.title}');
          print('剧集数量: ${state.videoDetail.episodes?.length ?? 0}');
          print('剧集列表:');
          for (int i = 0; i < (state.videoDetail.episodes?.length ?? 0); i++) {
            print('  第${i + 1}集: ${state.videoDetail.episodes![i]}');
          }
          print('=========================\n');

          setState(() {
            _videoDetail = state.videoDetail;
            _episodes = state.videoDetail.episodes ?? [];
          });
          break;
        } else if (state is MovieError) {
          throw Exception('获取视频详情失败: ${state.message}');
        }
      }
    } else {
      // 使用传入的参数
      print('使用Widget传入参数: source=${widget.videoSource}, id=${widget.videoId}');

      context.read<MovieBloc>().add(
            GetVideoDetailEvent(widget.videoSource, widget.videoId),
          );

      await for (final state in context.read<MovieBloc>().stream) {
        if (state is VideoDetailLoaded) {
          print('\n=== 视频详情加载成功 ===');
          print('视频标题: ${state.videoDetail.title}');
          print('剧集数量: ${state.videoDetail.episodes?.length ?? 0}');
          print('剧集列表:');
          for (int i = 0; i < (state.videoDetail.episodes?.length ?? 0); i++) {
            print('  第${i + 1}集: ${state.videoDetail.episodes![i]}');
          }
          print('=========================\n');

          setState(() {
            _videoDetail = state.videoDetail;
            _episodes = state.videoDetail.episodes ?? [];
          });
          break;
        } else if (state is MovieError) {
          throw Exception('获取视频详情失败: ${state.message}');
        }
      }
    }
  }

  Future<void> _playVideoFromUrl(String videoUrl) async {
    try {
      _disposeControllers();

      // 添加调试日志：检查传入的视频URL
      print('\n=== 播放视频URL调试 ===');
      print('传入的videoUrl: $videoUrl');
      print('当前选择的剧集索引: $_currentEpisodeIndex');
      print('总剧集数量: ${_episodes.length}');

      // 验证URL有效性
      if (videoUrl.isEmpty) {
        throw Exception('视频URL为空');
      }

      if (!videoUrl.startsWith('http')) {
        throw Exception('无效的视频URL格式: $videoUrl');
      }

      print('使用实际播放地址: $videoUrl');
      print('======================\n');

      _currentVideoUrl = videoUrl; // 保存当前播放URL

      setState(() {
        _isLoading = false;
        _hasError = false;
      });

      // 启动播放记录定时器
      _startPlayRecordTimer();
    } catch (e) {
      print('播放视频URL处理失败: $e');
      setState(() {
        _hasError = true;
        _errorMessage = '播放器初始化失败: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // 在播放器初始化后跳转到初始播放位置
  void _seekToInitialPosition() {
    // 只执行一次
    if (_hasSeekedToInitialPosition) return;

    // 检查是否有初始播放时间参数
    if (widget.initialPlayTime != null && widget.initialPlayTime! > 0) {
      final initialPosition = Duration(seconds: widget.initialPlayTime!);
      print('跳转到初始播放位置: $initialPosition');

      // 延迟执行跳转，确保播放器已完全初始化
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _playerController.seekTo(initialPosition);
            setState(() {
              _hasSeekedToInitialPosition = true;
            });
          }
        });
      });
    } else {
      setState(() {
        _hasSeekedToInitialPosition = true;
      });
    }
  }

  // 启动播放记录定时器
  void _startPlayRecordTimer() {
    _playRecordTimer?.cancel();
    _playRecordTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _savePlayRecord();
    });
  }

  // 保存播放记录
  Future<void> _savePlayRecord() async {
    if (_videoDetail == null || _currentVideoUrl == null) return;

    try {
      final key = '${widget.videoSource}+${widget.videoId}';
      final record = PlayRecordModel(
        title: _videoDetail!.title ?? widget.title,
        sourceName: _videoDetail!.sourceName ?? '',
        cover: _videoDetail!.poster ?? '',
        index: _currentEpisodeIndex + 1,
        totalEpisodes: _episodes.length,
        playTime: _position.inSeconds,
        totalTime: _duration.inSeconds,
        saveTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        year: _videoDetail!.year ?? '',
        searchTitle: key, // 添加searchTitle字段，用于记录解析
      );

      await _dataSource.savePlayRecord(key, record);
      print('播放记录已保存: ${record.title}');
    } catch (e) {
      print('保存播放记录失败: $e');
    }
  }

  void _playEpisode(int index) {
    if (index >= 0 && index < _episodes.length) {
      // 切换集数前先保存当前播放记录
      _savePlayRecord();

      setState(() {
        _currentEpisodeIndex = index;
      });
      _playVideoFromUrl(_episodes[index]);
    }
  }

  void _switchVideoSource(int sourceIndex) {
    if (_videoSources != null &&
        sourceIndex >= 0 &&
        sourceIndex < _videoSources!.length) {
      // 切换源前先保存当前播放记录
      _savePlayRecord();

      setState(() {
        _currentSourceIndex = sourceIndex;
        _currentEpisodeIndex = 0; // 重置到第一集
      });
      _initializeVideoPlayer(); // 重新初始化播放器
    }
  }

  void _showEpisodeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择集数',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _episodes.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _currentEpisodeIndex;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _playEpisode(index);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange : Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '第${index + 1}集',
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoSourceSelector() {
    if (_videoSources == null || _videoSources!.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择播放源',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _videoSources!.length,
                itemBuilder: (context, index) {
                  final source = _videoSources![index];
                  final isSelected = index == _currentSourceIndex;
                  // 获取该源的分辨率信息
                  final resolutionInfo = _resolutionInfoMap[index];

                  print(
                      '显示播放源: index=$index, source=${source.source}, resolutionInfo=$resolutionInfo');

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isSelected ? Colors.orange : Colors.grey[600]!,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      source.sourceName ?? source.source ?? '播放源${index + 1}',
                      style: TextStyle(
                        color: isSelected ? Colors.orange : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (source.note != null)
                          Text(
                            source.note!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        // 显示分辨率和速度信息
                        if (resolutionInfo != null)
                          Row(
                            children: [
                              // 分辨率标签
                              if (resolutionInfo.quality != 'N/A')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 8),
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
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.orange)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _switchVideoSource(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '播放速度',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(_playbackSpeeds.map((speed) {
              final isSelected = speed == _currentPlaybackSpeed;
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? Colors.orange : Colors.grey,
                ),
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: isSelected ? Colors.orange : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _currentPlaybackSpeed = speed;
                  });
                  // 通过FPlayerController设置播放速度
                  _playerController.setPlaybackSpeed(speed);
                  Navigator.pop(context);
                },
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // 退出前保存播放记录
    _savePlayRecord();
    // 恢复竖屏模式
    _setScreenToPortrait();
    // 返回true允许页面退出
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 视频播放器
            if (_isLoading)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      '正在加载...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            else if (_hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '播放失败',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? '未知错误',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initializeVideoPlayer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              )
            else if (_currentVideoUrl != null)
              VideoPlayerWidget(
                videoUrl: _currentVideoUrl!,
                title: widget.title,
                autoPlay: true,
                showControls: false, // 使用自定义控制栏
                playbackSpeeds: _playbackSpeeds,
                controller: _playerController,
                onInitialized: () {
                  setState(() {
                    _isLoading = false;
                    _hasError = false;
                  });
                  _resetHideControlsTimer(); // 启动控制栏自动隐藏
                },
                onError: (error) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = error;
                    _isLoading = false;
                  });
                },
                onPositionChanged: _onPositionChanged,
                onDurationChanged: (duration) {
                  setState(() {
                    _duration = duration;
                  });
                },
                onPlayStateChanged: (isPlaying) {
                  setState(() {
                    _isPlaying = isPlaying;
                    // 如果开始播放，重置缓冲状态
                    if (isPlaying && _isBuffering) {
                      _isBuffering = false;
                    }
                  });
                  if (isPlaying) {
                    _resetHideControlsTimer(); // 播放时自动隐藏控制栏
                  }
                },
                onCompleted: () {
                  // 视频播放完成时调用回调
                  widget.onVideoEnded?.call();
                },
              )
            else
              const Center(
                child: Text(
                  '播放器未初始化',
                  style: TextStyle(color: Colors.white),
                ),
              ),

            // 点击区域控制显示/隐藏控制栏（放在控制栏下面，避免拦截按钮点击）
            GestureDetector(
              onTap: _toggleControls,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),

            // 拖动后暂停时的缓冲提示（视频未播放且处于缓冲）
            if (_isBuffering && !_isPlaying)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 12),
                    Text(
                      '正在缓冲...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),

            // 自定义控制栏（放在最上层，确保按钮可以点击）
            if (_isControlsVisible) ..._buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: () {
        onPressed();
        // 防止事件冒泡到父级的GestureDetector
      },
      behavior: HitTestBehavior.opaque, // 确保按钮区域可以被点击
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // 构建控制栏的方法
  List<Widget> _buildControls() {
    return [
      // 顶部控制栏
      Positioned(
        top: 40,
        left: 16,
        right: 16,
        child: AnimatedOpacity(
          opacity: _isControlsVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Row(
            children: [
              // 返回按钮
              GestureDetector(
                onTap: () {
                  // 保存播放记录并恢复竖屏模式并返回
                  _savePlayRecord();
                  _setScreenToPortrait();
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 标题
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 全屏按钮
              GestureDetector(
                onTap: _toggleFullScreen,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              // 投屏按钮
              GestureDetector(
                onTap: _showCastDeviceSelector,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    _isCasting ? Icons.cast_connected : Icons.cast,
                    color: _isCasting ? Colors.orange : Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // 中间播放按钮区域（只在屏幕底部显示）
      Positioned(
        bottom: 120, // 放在底部控制栏上方
        left: 0,
        right: 0,
        child: AnimatedOpacity(
          opacity: _isControlsVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 音量减
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: GestureDetector(
                  onTap: () => _adjustVolume(-0.1),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.volume_down,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              // 播放/暂停按钮
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
              // 音量加
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: GestureDetector(
                  onTap: () => _adjustVolume(0.1),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // 底部控制栏
      Positioned(
        bottom: 20, // 降低位置，移到屏幕最底部
        left: 16,
        right: 16,
        child: AnimatedOpacity(
          opacity: _isControlsVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 进度条和时间显示
                Row(
                  children: [
                    Text(
                      _formatDuration(_isSeeking
                          ? (_dragPosition ?? _position)
                          : _position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque, // 确保进度条可以被点击和拖动
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16),
                                activeTrackColor: Colors.orange,
                                inactiveTrackColor: Colors.grey,
                                thumbColor: Colors.orange,
                              ),
                              child: Slider(
                                value: _duration.inMilliseconds > 0
                                    ? ((_isSeeking
                                                ? (_dragPosition ?? _position)
                                                : _position)
                                            .inMilliseconds /
                                        _duration.inMilliseconds)
                                    : 0.0,
                                onChanged: _onSeekChanged,
                                onChangeStart: _onSeekStart, // 添加拖动开始回调
                                onChangeEnd: _onSeekEnd, // 添加拖动结束回调
                              ),
                            ),
                          ),
                          // 缓冲状态指示器
                          if (_isBuffering)
                            Positioned(
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.orange),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '缓冲中',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 功能按钮行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 选集按钮
                    if (_episodes.length > 1)
                      _buildControlButton(
                        icon: Icons.list,
                        label: '选集',
                        onPressed: _showEpisodeSelector,
                      ),
                    // 播放源按钮
                    if (_videoSources != null && _videoSources!.length > 1)
                      _buildControlButton(
                        icon: Icons.source,
                        label: '播放源',
                        onPressed: _showVideoSourceSelector,
                      ),
                    // 倍速按钮
                    _buildControlButton(
                      icon: Icons.speed,
                      label: '${_currentPlaybackSpeed}x',
                      onPressed: _showSpeedSelector,
                    ),
                    // 音量显示
                    _buildControlButton(
                      icon: _volume > 0.5
                          ? Icons.volume_up
                          : (_volume > 0
                              ? Icons.volume_down
                              : Icons.volume_off),
                      label: '${(_volume * 100).round()}%',
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  // 时间格式化方法
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  void _onPositionChanged(Duration position) {
    // 如果在等待跳转完成，则当当前位置接近目标时结束拖动/缓冲状态
    if (_isSeeking && _seekTarget != null) {
      final diff = (position - _seekTarget!).inMilliseconds.abs();
      if (diff <= 800) {
        // 允许一定误差
        setState(() {
          _isSeeking = false;
          _isBuffering = false;
          _seekTarget = null;
          _dragPosition = null;
          _position = position; // 以播放器上报的位置为准
        });
        return;
      }
      // 未接近目标前不更新UI位置，保持停留在手松开的地方
      return;
    }
    // 正常更新位置
    if (!_isSeeking) {
      setState(() {
        _position = position;
        if (_isBuffering) {
          _isBuffering = false;
        }
      });
    }

    // 检查是否需要跳转到初始播放位置
    if (!_hasSeekedToInitialPosition) {
      _seekToInitialPosition();
    }
  }

  void _showCastDeviceSelector() {
    // 检查平台支持
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前平台不支持投屏功能')),
      );
      return;
    }

    if (_currentVideoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前没有可投屏的视频')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CastDeviceSelector(
        videoUrl: _currentVideoUrl!,
        title: widget.title,
        poster: _videoDetail?.poster,
        currentTime: _position.inSeconds,
        onDeviceConnected: (device) {
          // 投屏成功后的处理
          _onCastConnected(device);
        },
      ),
    ).then((_) {
      // 投屏选择器关闭后，检查投屏状态
      _checkCastingStatus();
    });
  }

  // 投屏成功后的处理
  void _onCastConnected(CastDevice device) {
    // 停止本地播放
    _playerController.pause();

    // 跨转到投屏管理页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CastControlPage(
          videoUrl: _currentVideoUrl!,
          title: widget.title,
          poster: _videoDetail?.poster,
          connectedDevice: device,
          onCastStopped: () {
            // 投屏停止后的处理
            _onCastStopped();
          },
        ),
      ),
    );
  }

  // 投屏停止后的处理
  void _onCastStopped() {
    setState(() {
      _isCasting = false;
    });
    // 可以选择继续本地播放
    // _playerController.play();
  }

  /// 检测所有视频源的分辨率信息
  Future<void> _detectVideoResolutions() async {
    print('=== 开始检测视频源分辨率 ===');
    print('视频源数量: ${_videoSources?.length ?? 0}');

    if (_videoSources == null || _videoSources!.isEmpty) {
      print('视频源为空，跳过检测');
      return;
    }

    try {
      // 收集所有有效的视频源并获取实际播放地址
      final List<String> urls = [];
      final List<int> indices = [];
      final List<Future<String?>> detailFutures = [];

      for (int i = 0; i < _videoSources!.length; i++) {
        final source = _videoSources![i];
        print('检查视频源 $i: id=${source.id}');

        if (source.source != null &&
            source.source!.isNotEmpty &&
            source.id.isNotEmpty) {
          // 获取视频详情以获取实际播放地址
          detailFutures
              .add(_getVideoDetailForResolution(source.source!, source.id, i));
          indices.add(i);
        } else {
          print('跳过无效视频源: index=$i, id=${source.id}');
        }
      }

      if (detailFutures.isEmpty) {
        print('没有有效的视频源，跳过检测');
        return;
      }

      print('等待所有视频详情获取完成，任务数量: ${detailFutures.length}');
      final results = await Future.wait(detailFutures);
      print('所有视频详情获取完成');

      // 收集有效的播放地址
      for (int i = 0; i < results.length; i++) {
        final url = results[i];
        if (url != null && url.isNotEmpty) {
          urls.add(url);
          print('获取到源的视频URL: index=${indices[i]}, url=$url');
        } else {
          print('源没有返回有效的视频URL: index=${indices[i]}');
        }
      }

      if (urls.isEmpty) {
        print('没有获取到任何有效的视频URL，跳过检测');
        return;
      }

      // 批量获取分辨率信息
      print('开始批量获取分辨率信息，URL数量: ${urls.length}');
      print('URL列表: $urls');

      final resolutionMap =
          await VideoResolutionDetector.getVideoResolutionsFromM3u8List(urls);
      print('分辨率信息获取完成，结果数量: ${resolutionMap.length}');
      print('分辨率映射: $resolutionMap');

      // 更新分辨率信息映射
      int urlIndex = 0;
      for (int i = 0; i < results.length; i++) {
        final url = results[i];
        if (url != null && url.isNotEmpty) {
          final index = indices[i];
          print('处理结果: index=$index, url=$url');

          if (resolutionMap.containsKey(url)) {
            print(
                '设置分辨率信息: index=$index, url=$url, info=${resolutionMap[url]}');
            setState(() {
              _resolutionInfoMap[index] = resolutionMap[url]!;
            });
          } else {
            print('未找到URL的分辨率信息: $url');
          }
          urlIndex++;
        }
      }

      print('=== 视频源分辨率检测完成 ===');
    } catch (e, stackTrace) {
      print('检测视频分辨率时出错: $e');
      print('错误堆栈: $stackTrace');
    }
  }

  /// 获取视频详情用于分辨率检测
  Future<String?> _getVideoDetailForResolution(
      String source, String id, int index) async {
    try {
      print('获取视频详情用于分辨率检测: source=$source, index=$index');

      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('api_server_address');

      if (serverUrl == null) {
        print('服务器地址为空');
        return null;
      }

      print('使用服务器地址: $serverUrl');
      final apiClient = ApiClient(baseUrl: serverUrl);
      final dataSource = MovieRemoteDataSourceImpl(apiClient);

      print('开始获取视频详情: source=$source');
      final videoDetail = await dataSource.getVideoDetail(source, id);
      print(
          '获取到视频详情: source=$source, episodes数量=${videoDetail.episodes?.length ?? 0}');

      if (videoDetail.episodes != null && videoDetail.episodes!.isNotEmpty) {
        final firstEpisodeUrl = videoDetail.episodes!.first;
        print('第一集URL: $firstEpisodeUrl');
        return firstEpisodeUrl;
      } else {
        print('没有剧集信息');
        return null;
      }
    } catch (e) {
      print('获取视频详情失败: source=$source, 错误: $e');
      return null;
    }
  }
}
