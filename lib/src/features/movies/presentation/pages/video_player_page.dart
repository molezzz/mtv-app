import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_event.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_state.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video_detail.dart';
import 'package:mtv_app/src/core/services/cast_service.dart';
import 'package:mtv_app/src/features/movies/presentation/widgets/cast_device_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
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
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
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
    
    if (currentSource != null) {
      // 使用当前选中的视频源信息
      context.read<MovieBloc>().add(
        GetVideoDetailEvent(currentSource.source ?? widget.videoSource, currentSource.id),
      );
      
      // 监听状态变化
      await for (final state in context.read<MovieBloc>().stream) {
        if (state is VideoDetailLoaded) {
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
      context.read<MovieBloc>().add(
        GetVideoDetailEvent(widget.videoSource, widget.videoId),
      );
      
      await for (final state in context.read<MovieBloc>().stream) {
        if (state is VideoDetailLoaded) {
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

      // 使用示例视频URL进行测试
      // 实际项目中需要从 episodes 中解析出实际的播放链接
      const testVideoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
      
      _currentVideoUrl = testVideoUrl; // 保存当前播放URL
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(testVideoUrl),
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: false, // 已经是全屏模式
        allowMuting: true,
        showControls: true,
        playbackSpeeds: _playbackSpeeds,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  '播放出错',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
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
    if (_videoSources != null && sourceIndex >= 0 && sourceIndex < _videoSources!.length) {
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
                      backgroundColor: isSelected ? Colors.orange : Colors.grey[600],
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      source.sourceName ?? source.source ?? '播放源${index + 1}',
                      style: TextStyle(
                        color: isSelected ? Colors.orange : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? Colors.orange : Colors.grey,
                ),
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: isSelected ? Colors.orange : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _currentPlaybackSpeed = speed;
                  });
                  _videoPlayerController?.setPlaybackSpeed(speed);
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
          else if (_chewieController != null)
            Chewie(controller: _chewieController!)
          else
            const Center(
              child: Text(
                '播放器未初始化',
                style: TextStyle(color: Colors.white),
              ),
            ),

          // 自定义控制栏
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
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
                  // 投屏按钮
                  IconButton(
                    onPressed: _showCastDeviceSelector,
                    icon: Icon(
                      _isCasting ? Icons.cast_connected : Icons.cast,
                      color: _isCasting ? Colors.orange : Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部控制栏
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: _isControlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
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
                  ],
                ),
              ),
            ),
          ),

          // 点击区域控制显示/隐藏控制栏
          GestureDetector(
            onTap: () {
              setState(() {
                _isControlsVisible = !_isControlsVisible;
              });
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
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
      onTap: onPressed,
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
        currentTime: _videoPlayerController?.value.position.inSeconds,
      ),
    ).then((_) {
      // 投屏选择器关闭后，检查投屏状态
      _checkCastingStatus();
    });
  }
}