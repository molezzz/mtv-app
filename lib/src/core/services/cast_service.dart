import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CastService {
  static const MethodChannel _channel = MethodChannel('mtv_app/cast');

  /// 初始化投屏服务
  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
    } on PlatformException catch (e) {
      debugPrint('Failed to initialize cast service: ${e.message}');
    }
  }

  /// 获取可用的投屏设备列表
  static Future<List<CastDevice>> getAvailableDevices() async {
    try {
      final List<dynamic> devices = await _channel.invokeMethod('getAvailableDevices');
      return devices.map((device) => CastDevice.fromMap(device)).toList();
    } on PlatformException catch (e) {
      debugPrint('Failed to get available devices: ${e.message}');
      return [];
    }
  }

  /// 连接到指定设备
  static Future<bool> connectToDevice(String deviceId) async {
    try {
      final bool result = await _channel.invokeMethod('connectToDevice', {
        'deviceId': deviceId,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to connect to device: ${e.message}');
      return false;
    }
  }

  /// 开始投屏视频
  static Future<bool> castVideo({
    required String videoUrl,
    required String title,
    String? poster,
    int? currentTime,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('castVideo', {
        'videoUrl': videoUrl,
        'title': title,
        'poster': poster,
        'currentTime': currentTime ?? 0,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to cast video: ${e.message}');
      return false;
    }
  }

  /// 控制播放/暂停
  static Future<void> togglePlayPause() async {
    try {
      await _channel.invokeMethod('togglePlayPause');
    } on PlatformException catch (e) {
      debugPrint('Failed to toggle play/pause: ${e.message}');
    }
  }

  /// 调整音量
  static Future<void> setVolume(double volume) async {
    try {
      await _channel.invokeMethod('setVolume', {'volume': volume});
    } on PlatformException catch (e) {
      debugPrint('Failed to set volume: ${e.message}');
    }
  }

  /// 跳转到指定时间
  static Future<void> seekTo(int timeInSeconds) async {
    try {
      await _channel.invokeMethod('seekTo', {'time': timeInSeconds});
    } on PlatformException catch (e) {
      debugPrint('Failed to seek: ${e.message}');
    }
  }

  /// 停止投屏
  static Future<void> stopCasting() async {
    try {
      await _channel.invokeMethod('stopCasting');
    } on PlatformException catch (e) {
      debugPrint('Failed to stop casting: ${e.message}');
    }
  }

  /// 断开连接
  static Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      debugPrint('Failed to disconnect: ${e.message}');
    }
  }

  /// 检查是否已连接到设备
  static Future<bool> isConnected() async {
    try {
      final bool result = await _channel.invokeMethod('isConnected');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to check connection status: ${e.message}');
      return false;
    }
  }

  /// 获取当前播放状态
  static Future<CastPlaybackState?> getPlaybackState() async {
    try {
      final Map<dynamic, dynamic>? state = await _channel.invokeMethod('getPlaybackState');
      if (state != null) {
        return CastPlaybackState.fromMap(state.cast<String, dynamic>());
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint('Failed to get playback state: ${e.message}');
      return null;
    }
  }

  /// 开始设备发现
  static Future<void> startDiscovery() async {
    try {
      await _channel.invokeMethod('startDiscovery');
    } on PlatformException catch (e) {
      debugPrint('Failed to start discovery: ${e.message}');
    }
  }

  /// 停止设备发现
  static Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod('stopDiscovery');
    } on PlatformException catch (e) {
      debugPrint('Failed to stop discovery: ${e.message}');
    }
  }
}

/// 投屏设备模型
class CastDevice {
  final String id;
  final String name;
  final String type; // 'chromecast', 'airplay', etc.
  final bool isAvailable;

  const CastDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isAvailable = true,
  });

  factory CastDevice.fromMap(Map<dynamic, dynamic> map) {
    return CastDevice(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isAvailable': isAvailable,
    };
  }

  @override
  String toString() {
    return 'CastDevice{id: $id, name: $name, type: $type, isAvailable: $isAvailable}';
  }
}

/// 播放状态模型
class CastPlaybackState {
  final bool isPlaying;
  final int currentTime; // 秒
  final int duration; // 秒
  final double volume; // 0.0 - 1.0

  const CastPlaybackState({
    required this.isPlaying,
    required this.currentTime,
    required this.duration,
    required this.volume,
  });

  factory CastPlaybackState.fromMap(Map<String, dynamic> map) {
    return CastPlaybackState(
      isPlaying: map['isPlaying'] ?? false,
      currentTime: map['currentTime'] ?? 0,
      duration: map['duration'] ?? 0,
      volume: (map['volume'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isPlaying': isPlaying,
      'currentTime': currentTime,
      'duration': duration,
      'volume': volume,
    };
  }

  @override
  String toString() {
    return 'CastPlaybackState{isPlaying: $isPlaying, currentTime: $currentTime, duration: $duration, volume: $volume}';
  }
}