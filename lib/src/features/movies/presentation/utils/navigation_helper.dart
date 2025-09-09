import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:mtv_app/src/features/movies/data/repositories/movie_repository_impl.dart';
import 'package:mtv_app/src/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/search_videos.dart';
import 'package:mtv_app/src/features/movies/presentation/pages/movie_detail_page.dart';
import 'package:mtv_app/src/features/movies/domain/entities/video.dart';

/// 导航辅助类，用于处理电影详情页导航
/// 确保完全独立于主MovieBloc，避免状态冲突
class NavigationHelper {
  static bool _isNavigating = false;

  /// 安全导航到电影详情页
  /// 使用独立的API客户端和搜索逻辑，不影响主页面状态
  static Future<void> navigateToMovieDetail({
    required BuildContext context,
    required String title,
    String? imageUrl,
    String? source,
    String? id,
    Video? video, // 如果已有Video对象，直接使用
  }) async {
    // 防止重复导航
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      // 如果已有video对象，直接导航
      if (video != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MovieDetailPage(
              source: video.source ?? 'unknown',
              id: video.id,
              title: title,
              poster: imageUrl,
            ),
          ),
        );
        return;
      }

      // 如果已有source和id，直接导航
      if (source != null && id != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MovieDetailPage(
              source: source,
              id: id,
              title: title,
              poster: imageUrl,
            ),
          ),
        );
        return;
      }

      // 否则需要搜索获取source和id
      await _searchAndNavigate(
        context: context,
        title: title,
        imageUrl: imageUrl,
      );
    } finally {
      _isNavigating = false;
    }
  }

  /// 执行独立搜索并导航
  static Future<void> _searchAndNavigate({
    required BuildContext context,
    required String title,
    String? imageUrl,
  }) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在搜索...'),
          ],
        ),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final serverAddress = prefs.getString('api_server_address');

      if (serverAddress == null) {
        if (context.mounted) {
          Navigator.of(context).pop(); // 关闭加载对话框
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未配置服务器地址'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 创建完全独立的API客户端和仓库
      final apiClient = ApiClient(baseUrl: serverAddress);
      final repository = MovieRepositoryImpl(
        remoteDataSource: MovieRemoteDataSourceImpl(apiClient),
      );
      final searchVideos = SearchVideos(repository);

      // 执行搜索
      final videos = await searchVideos(title);

      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框

        if (videos.isNotEmpty) {
          // 找到搜索结果，使用第一个匹配的视频
          final video = videos.first;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MovieDetailPage(
                source: video.source ?? 'unknown',
                id: video.id,
                title: title,
                poster: imageUrl,
              ),
            ),
          );
        } else {
          // 没有找到搜索结果
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('未找到"$title"的视频源'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 搜索失败
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('搜索失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}