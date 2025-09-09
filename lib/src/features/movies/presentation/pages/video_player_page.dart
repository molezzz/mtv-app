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
import 'package:mtv_app/src/features/movies/presentation/widgets/video_player_widget.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoSource;
  final String videoId;
  final String? episodeUrl;
  final String title;
  final List<Video>? videoSources;
  final int? selectedSourceIndex;

  const VideoPlayerPage({
    super.key,
    required this.videoSource,
    required this.videoId,
    this.episodeUrl,
    required this.title,
    this.videoSources,
    this.selectedSourceIndex,
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

  final List<double> _playbackSpeeds = [0.5, 1.0, 2.0];

  @override
  void initState() {
    super.initState();
    _videoSources = widget.videoSources;
    _currentSourceIndex = widget.selectedSourceIndex ?? 0;
    _initializeVideoPlayer();
    _setScreenToLandscape();
    WakelockPlus.enable(); // 保持屏幕常亮
    _checkCastingStatus();
  }

  @override
  void dispose() {
    _disposeControllers();
    _hideControlsTimer?.cancel(); // 取消计时器
    _setScreenToPortrait();
    WakelockPlus.disable(); // 恢复屏幕锁定
    // 只在移动平台停止设备发现
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      CastService.stopDiscovery();
    }
    super.dispose();
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
    // AliPlayer会在AliPlayerWidget的dispose方法中自动销毁
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
    _playerController.seekTo(newPosition);
    _showControls();
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
    } catch (e) {
      print('播放视频URL处理失败: $e');
      setState(() {
        _hasError = true;
        _errorMessage = '播放器初始化失败: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _playEpisode(int index) {
    if (index >= 0 && index < _episodes.length) {
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
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isSelected ? Colors.orange : Colors.grey[600],
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
                    subtitle: source.note != null
                        ? Text(
                            source.note!,
                            style: const TextStyle(color: Colors.grey),
                          )
                        : null,
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
                  // 通过AliPlayerController设置播放速度
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              onPositionChanged: (position) {
                setState(() {
                  _position = position;
                });
              },
              onDurationChanged: (duration) {
                setState(() {
                  _duration = duration;
                });
              },
              onPlayStateChanged: (isPlaying) {
                setState(() {
                  _isPlaying = isPlaying;
                });
                if (isPlaying) {
                  _resetHideControlsTimer(); // 播放时自动隐藏控制栏
                }
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

          // 自定义控制栏（放在最上层，确保按钮可以点击）
          if (_isControlsVisible) ..._buildControls(),
        ],
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
                      _formatDuration(_position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque, // 确保进度条可以被点击和拖动
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8),
                            overlayShape:
                                const RoundSliderOverlayShape(overlayRadius: 16),
                            activeTrackColor: Colors.orange,
                            inactiveTrackColor: Colors.grey,
                            thumbColor: Colors.orange,
                          ),
                          child: Slider(
                            value: _duration.inMilliseconds > 0
                                ? _position.inMilliseconds /
                                    _duration.inMilliseconds
                                : 0.0,
                            onChanged: _onSeekChanged,
                          ),
                        ),
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
      ),
    ).then((_) {
      // 投屏选择器关闭后，检查投屏状态
      _checkCastingStatus();
    });
  }
}
