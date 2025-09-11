import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fplayer/fplayer.dart';

/// FPlayer视频播放器组件
/// 基于fplayer的视频播放器，支持m3u8等多种格式
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final bool autoPlay;
  final bool showControls;
  final List<double> playbackSpeeds;
  final CustomVideoPlayerController? controller;
  final VoidCallback? onInitialized;
  final Function(String)? onError;
  final Function(Duration)? onPositionChanged;
  final Function(Duration)? onDurationChanged;
  final Function()? onCompleted;
  final Function(bool)? onPlayStateChanged;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.title,
    this.autoPlay = true,
    this.showControls = true,
    this.playbackSpeeds = const [0.5, 1.0, 2.0],
    this.controller,
    this.onInitialized,
    this.onError,
    this.onPositionChanged,
    this.onDurationChanged,
    this.onCompleted,
    this.onPlayStateChanged,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

// 自定义控制器类，保持与原有接口兼容
class CustomVideoPlayerController {
  _VideoPlayerWidgetState? _state;

  void _attach(_VideoPlayerWidgetState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void play() => _state?.play();
  void pause() => _state?.pause();
  void stop() => _state?.stop();
  void seekTo(Duration position) => _state?.seekTo(position);
  void setPlaybackSpeed(double speed) => _state?.setPlaybackSpeed(speed);
  void setVolume(double volume) => _state?.setVolume(volume);

  bool get isInitialized => _state?.isInitialized ?? false;
  bool get isPlaying => _state?.isPlaying ?? false;
  bool get hasError => _state?.hasError ?? false;
  String? get errorMessage => _state?.errorMessage;
  Duration get duration => _state?.duration ?? Duration.zero;
  Duration get position => _state?.position ?? Duration.zero;
  double get currentSpeed => _state?.currentSpeed ?? 1.0;
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late FPlayer _fPlayer;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _currentSpeed = 1.0;
  Timer? _positionTimer;
  bool _isSeeking = false; // 添加一个标志来跟踪是否正在拖动进度条

  @override
  void initState() {
    super.initState();
    // 连接控制器
    widget.controller?._attach(this);
    _initializePlayer();
  }

  @override
  void dispose() {
    // 断开控制器连接
    widget.controller?._detach();
    _positionTimer?.cancel();
    _fPlayer.release();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      print('\n=== FPlayer 初始化开始 ===');
      print('视频URL: ${widget.videoUrl}');

      // 创建FPlayer实例
      _fPlayer = FPlayer();

      // 配置播放器选项
      await _setupPlayerOptions();

      // 设置播放器监听器
      _setupPlayerListeners();

      // 设置数据源并开始播放
      await _fPlayer.setDataSource(
        widget.videoUrl,
        autoPlay: widget.autoPlay,
        showCover: true,
      );

      print('FPlayer 初始化成功！');
      print('======================\n');
    } catch (e) {
      print('FPlayer 初始化失败: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'FPlayer 初始化失败: ${e.toString()}';
        _isLoading = false;
      });
      widget.onError?.call(_errorMessage!);
    }
  }

  Future<void> _setupPlayerOptions() async {
    // 基本播放配置
    await _fPlayer.setOption(FOption.hostCategory, "enable-snapshot", 1);
    await _fPlayer.setOption(FOption.hostCategory, "request-screen-on", 1);
    await _fPlayer.setOption(FOption.hostCategory, "request-audio-focus", 1);

    // 网络和缓冲配置
    await _fPlayer.setOption(FOption.playerCategory, "reconnect", 20);
    await _fPlayer.setOption(FOption.playerCategory, "framedrop", 20);
    await _fPlayer.setOption(FOption.playerCategory, "enable-accurate-seek", 1);
    await _fPlayer.setOption(FOption.playerCategory, "mediacodec", 1);
    await _fPlayer.setOption(FOption.playerCategory, "packet-buffering", 0);
    await _fPlayer.setOption(FOption.playerCategory, "soundtouch", 1);

    print('FPlayer 配置选项设置完成');
  }

  void _setupPlayerListeners() {
    // 监听播放器状态变化
    _fPlayer.addListener(() {
      final state = _fPlayer.state;
      final value = _fPlayer.value;

      // 更新播放状态
      if (state == FState.prepared && !_isInitialized) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _hasError = false;
          _duration = value.duration;
        });
        widget.onInitialized?.call();
        print('FPlayer 准备完成，时长: $_duration');
      }

      // 更新播放/暂停状态
      final isPlaying = state == FState.started;
      if (_isPlaying != isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
        widget.onPlayStateChanged?.call(isPlaying);

        // 启动或停止位置更新定时器
        if (isPlaying) {
          _startPositionTimer();
        } else {
          _stopPositionTimer();
        }
      }

      // 更新播放位置和时长（仅在非拖动状态下更新UI）
      if (!_isSeeking) {
        if (value.duration != _duration && value.duration > Duration.zero) {
          setState(() {
            _duration = value.duration;
          });
          widget.onDurationChanged?.call(_duration);
        }

        // 只有在非拖动状态时才更新位置，避免拖动时的跳动
        final currentPos = _fPlayer.currentPos;
        if (currentPos != _position) {
          setState(() {
            _position = currentPos;
          });
          widget.onPositionChanged?.call(_position);
        }
      }

      // 处理播放完成
      if (state == FState.completed) {
        widget.onCompleted?.call();
        print('FPlayer 播放完成');
      }

      // 处理错误
      if (state == FState.error) {
        final errorMsg = 'FPlayer 播放错误: ${value.exception.toString()}';
        setState(() {
          _hasError = true;
          _errorMessage = errorMsg;
          _isLoading = false;
        });
        widget.onError?.call(errorMsg);
        print('FPlayer 错误: $errorMsg');
      }
    });
  }

  void _startPositionTimer() {
    _stopPositionTimer(); // 确保没有重复的定时器
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_fPlayer.state == FState.started && !_isSeeking) {
        // 使用 FPlayer 的当前位置
        final currentPos = _fPlayer.currentPos;
        if (currentPos != _position) {
          setState(() {
            _position = currentPos;
          });
          widget.onPositionChanged?.call(_position);
        }
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  // 控制器方法实现
  void play() async {
    try {
      await _fPlayer.start();
    } catch (e) {
      print('播放失败: $e');
    }
  }

  void pause() async {
    try {
      await _fPlayer.pause();
    } catch (e) {
      print('暂停失败: $e');
    }
  }

  void stop() async {
    try {
      await _fPlayer.stop();
    } catch (e) {
      print('停止失败: $e');
    }
  }

  void seekTo(Duration position) async {
    try {
      // 设置拖动状态
      setState(() {
        _isSeeking = true;
        _position = position; // 立即更新UI显示
      });

      // 执行跳转
      await _fPlayer.seekTo(position.inMilliseconds);

      // 跳转完成后重置状态，并通知位置变化
      setState(() {
        _isSeeking = false;
      });

      // 通知位置变化（跳转完成后）
      widget.onPositionChanged?.call(position);
    } catch (e) {
      print('跳转失败: $e');
      // 出错时也要重置状态
      setState(() {
        _isSeeking = false;
      });
    }
  }

  void setPlaybackSpeed(double speed) async {
    try {
      await _fPlayer.setSpeed(speed);
      setState(() {
        _currentSpeed = speed;
      });
    } catch (e) {
      print('设置播放速度失败: $e');
    }
  }

  void setVolume(double volume) async {
    try {
      await _fPlayer.setVolume(volume);
    } catch (e) {
      print('设置音量失败: $e');
    }
  }

  // Getter 方法
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  Duration get duration => _duration;
  Duration get position => _position;
  double get currentSpeed => _currentSpeed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // FPlayer 视图
          if (_isInitialized && !_hasError)
            FView(
              player: _fPlayer,
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              fsFit: FFit.contain, // 全屏模式下的填充
              fit: FFit.contain, // 正常模式下的填充
            ),

          // 加载指示器
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
            ),

          // 错误显示
          if (_hasError)
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
                  Text(
                    _errorMessage ?? '播放出错',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _initializePlayer();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
