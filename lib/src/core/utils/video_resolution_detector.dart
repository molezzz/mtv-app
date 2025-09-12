import 'package:dio/dio.dart';

/// 视频分辨率检测结果
class VideoResolutionInfo {
  final String quality; // 分辨率标签，如 "4K", "1080p", "720p" 等
  final String loadSpeed; // 下载速度，如 "1.2 MB/s"
  final int pingTime; // 延迟时间，单位毫秒

  VideoResolutionInfo({
    required this.quality,
    required this.loadSpeed,
    required this.pingTime,
  });

  @override
  String toString() {
    return 'VideoResolutionInfo(quality: $quality, loadSpeed: $loadSpeed, pingTime: $pingTime ms)';
  }
}

/// 视频分辨率检测器
/// 用于检测M3U8视频源的分辨率、下载速度和网络延迟
class VideoResolutionDetector {
  static final Dio _dio = Dio();

  // 初始化Dio配置
  static void _initDio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    };
  }

  /// 根据视频宽度判断视频质量等级
  static String _getQualityFromWidth(int width) {
    if (width >= 3840) {
      return '4K'; // 4K: 3840x2160
    } else if (width >= 2560) {
      return '2K'; // 2K: 2560x1440
    } else if (width >= 1920) {
      return '1080p'; // 1080p: 1920x1080
    } else if (width >= 1280) {
      return '720p'; // 720p: 1280x720
    } else if (width >= 854) {
      return '480p';
    } else {
      return 'SD';
    }
  }

  /// 从M3U8内容中提取视频宽度信息
  static int _extractWidthFromM3u8(String m3u8Content) {
    // 查找STREAM-INF标签中的分辨率信息
    final regExp = RegExp(r'RESOLUTION=(\d+)x(\d+)');
    final match = regExp.firstMatch(m3u8Content);

    if (match != null) {
      final width = int.tryParse(match.group(1) ?? '0') ?? 0;
      final height = int.tryParse(match.group(2) ?? '0') ?? 0;
      // 返回较大的维度作为参考
      return width > height ? width : height;
    }

    // 如果没有找到明确的分辨率信息，返回默认值
    return 0;
  }

  /// 测量网络延迟(Ping)
  static Future<int> _measurePing(String url) async {
    try {
      final startTime = DateTime.now().millisecondsSinceEpoch;
      await _dio.head(url);
      final endTime = DateTime.now().millisecondsSinceEpoch;
      return endTime - startTime;
    } catch (e) {
      // 如果HEAD请求失败，尝试GET请求
      try {
        final startTime = DateTime.now().millisecondsSinceEpoch;
        await _dio.get(url,
            options: Options(
                responseType: ResponseType.bytes,
                receiveTimeout: const Duration(seconds: 5)));
        final endTime = DateTime.now().millisecondsSinceEpoch;
        return endTime - startTime;
      } catch (e2) {
        // 如果都失败了，返回一个较大的默认值
        return 500;
      }
    }
  }

  /// 测量下载速度
  static Future<String> _measureDownloadSpeed(String url) async {
    try {
      final startTime = DateTime.now().millisecondsSinceEpoch;
      final response = await _dio.get(url,
          options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(seconds: 10)));
      final endTime = DateTime.now().millisecondsSinceEpoch;

      if (response.data is List<int>) {
        final sizeInBytes = response.data.length;
        final durationInMillis = endTime - startTime;

        if (durationInMillis > 0) {
          final speedInKBps = sizeInBytes / 1024 / (durationInMillis / 1000);

          if (speedInKBps >= 1024) {
            return '${(speedInKBps / 1024).toStringAsFixed(1)} MB/s';
          } else {
            return '${speedInKBps.toStringAsFixed(1)} KB/s';
          }
        }
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  /// 从M3U8 URL获取视频分辨率信息
  /// 返回包含分辨率、下载速度和延迟的VideoResolutionInfo对象
  static Future<VideoResolutionInfo> getVideoResolutionFromM3u8(
      String m3u8Url) async {
    _initDio();

    try {
      // 并行执行Ping测量和M3U8内容获取
      final pingFuture = _measurePing(m3u8Url);
      final m3u8Response = await _dio.get(m3u8Url);
      final downloadSpeedFuture = _measureDownloadSpeed(m3u8Url);

      final pingTime = await pingFuture;
      final m3u8Content = m3u8Response.data.toString();
      final loadSpeed = await downloadSpeedFuture;

      // 从M3U8内容中提取分辨率信息
      final width = _extractWidthFromM3u8(m3u8Content);
      final quality = width > 0 ? _getQualityFromWidth(width) : 'N/A';

      return VideoResolutionInfo(
        quality: quality,
        loadSpeed: loadSpeed,
        pingTime: pingTime,
      );
    } catch (e) {
      // 如果出现任何错误，返回默认值
      return VideoResolutionInfo(
        quality: 'N/A',
        loadSpeed: 'N/A',
        pingTime: 500,
      );
    }
  }

  /// 批量获取多个视频源的分辨率信息
  static Future<Map<String, VideoResolutionInfo>>
      getVideoResolutionsFromM3u8List(List<String> m3u8Urls) async {
    final Map<String, VideoResolutionInfo> results = {};

    // 并行处理所有URL
    final futures = m3u8Urls
        .map((url) =>
            getVideoResolutionFromM3u8(url).then((info) => results[url] = info))
        .toList();
    await Future.wait(futures);

    return results;
  }
}
