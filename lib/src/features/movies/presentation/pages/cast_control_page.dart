import 'package:flutter/material.dart';
import 'package:mtv_app/src/core/services/cast_service.dart';
import 'package:mtv_app/src/features/movies/presentation/widgets/cast_device_selector.dart';

class CastControlPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? poster;
  final CastDevice connectedDevice;
  final VoidCallback? onCastStopped;

  const CastControlPage({
    super.key,
    required this.videoUrl,
    required this.title,
    this.poster,
    required this.connectedDevice,
    this.onCastStopped,
  });

  @override
  State<CastControlPage> createState() => _CastControlPageState();
}

class _CastControlPageState extends State<CastControlPage> {
  bool _isPlaying = true;
  bool _isLoading = false;
  CastDevice? _currentDevice;
  CastPlaybackState? _playbackState;

  @override
  void initState() {
    super.initState();
    _currentDevice = widget.connectedDevice;
    _startPlaybackStatePolling();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startPlaybackStatePolling() {
    // 定期获取播放状态
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _updatePlaybackState();
        _startPlaybackStatePolling();
      }
    });
  }

  Future<void> _updatePlaybackState() async {
    try {
      final state = await CastService.getPlaybackState();
      if (mounted && state != null) {
        setState(() {
          _playbackState = state;
          _isPlaying = state.isPlaying;
        });
      }
    } catch (e) {
      // 静默处理错误
    }
  }

  Future<void> _togglePlayPause() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await CastService.togglePlayPause();
      setState(() {
        _isPlaying = !_isPlaying;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopCasting() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await CastService.stopCasting();
      await CastService.disconnect();

      if (mounted) {
        widget.onCastStopped?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已停止投屏'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('停止投屏失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _switchDevice() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => CastDeviceSelector(
        videoUrl: widget.videoUrl,
        title: widget.title,
        poster: widget.poster,
        currentTime: _playbackState?.currentTime,
        onDeviceConnected: (device) {
          setState(() {
            _currentDevice = device;
          });
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '投屏控制',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 设备信息卡片
            Card(
              color: Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              _getDeviceColor(_currentDevice?.type ?? ''),
                          child: Icon(
                            _getDeviceIcon(_currentDevice?.type ?? ''),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentDevice?.name ?? '未知设备',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currentDevice?.typeDisplayName ?? '',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _switchDevice,
                          icon: const Icon(
                            Icons.swap_horiz,
                            color: Colors.orange,
                          ),
                          tooltip: '切换设备',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _isPlaying ? Colors.green[700] : Colors.grey[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isPlaying ? '正在播放' : '已暂停',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 正在播放的视频信息
            Card(
              color: Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '正在播放',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (widget.poster != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.poster!,
                              width: 60,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[700],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.movie,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              if (_playbackState != null) ...[
                                Text(
                                  '${_formatTime(_playbackState!.currentTime)} / ${_formatTime(_playbackState!.duration)}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _playbackState!.duration > 0
                                      ? _playbackState!.currentTime /
                                          _playbackState!.duration
                                      : 0.0,
                                  backgroundColor: Colors.grey[600],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.orange),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  onPressed: _isLoading ? null : _togglePlayPause,
                  icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                  label: _isPlaying ? '暂停' : '播放',
                ),
                _buildControlButton(
                  onPressed: _isLoading ? null : _stopCasting,
                  icon: Icons.stop,
                  label: '停止投屏',
                  color: Colors.red,
                ),
              ],
            ),

            const Spacer(),

            // 底部提示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '视频正在 ${_currentDevice?.name ?? "投屏设备"} 上播放',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color ?? Colors.orange,
            shape: BoxShape.circle,
          ),
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: onPressed,
                  icon: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'chromecast':
      case 'android_tv':
        return Icons.cast;
      case 'dlna':
        return Icons.tv;
      case 'airplay':
      case 'apple_tv':
        return Icons.airplay;
      default:
        return Icons.tv;
    }
  }

  Color _getDeviceColor(String type) {
    switch (type.toLowerCase()) {
      case 'chromecast':
      case 'android_tv':
        return Colors.green;
      case 'dlna':
        return Colors.blue;
      case 'airplay':
      case 'apple_tv':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
