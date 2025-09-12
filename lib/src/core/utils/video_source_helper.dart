import 'dart:async';

import 'package:mtv_app/src/features/movies/domain/entities/video.dart';
import 'package:mtv_app/src/core/utils/video_resolution_detector.dart';
import 'package:mtv_app/src/features/movies/data/repositories/movie_repository_impl.dart';
import 'package:mtv_app/src/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoSourceHelper {
  final Function(Map<String, VideoResolutionInfo>, List<Video>) onUpdate;
  final Function(bool) onLoadingStateChanged;

  VideoSourceHelper({
    required this.onUpdate,
    required this.onLoadingStateChanged,
  });

  Future<void> detectAndSortSources(List<Video> videoSources) async {
    if (videoSources.isEmpty) {
      onLoadingStateChanged(false);
      return;
    }

    onLoadingStateChanged(true);
    final resolutionInfoMap = <String, VideoResolutionInfo>{};

    try {
      final sourceUrls = <String, String>{}; // sourceId -> m3u8Url
      final detailFutures = videoSources.map((source) {
        return _getVideoDetailForResolution(source.source!, source.id)
            .then((url) {
          if (url != null) {
            sourceUrls[source.id] = url;
          }
        });
      });
      await Future.wait(detailFutures);

      if (sourceUrls.isEmpty) {
        onLoadingStateChanged(false);
        return;
      }

      final detectionCompleters = <Completer<void>>[];
      sourceUrls.forEach((sourceId, url) {
        final completer = Completer<void>();
        detectionCompleters.add(completer);

        VideoResolutionDetector.streamVideoResolutionInfo(url).listen(
          (info) {
            resolutionInfoMap[sourceId] = info;
            final sortedSources = List<Video>.from(videoSources)..sort((a, b) => _compareSources(a, b, resolutionInfoMap));
            onUpdate(resolutionInfoMap, sortedSources);
          },
          onError: (e) {
            resolutionInfoMap[sourceId] = VideoResolutionInfo(
                quality: '错误', loadSpeed: 'N/A', pingTime: 9999);
            final sortedSources = List<Video>.from(videoSources)..sort((a, b) => _compareSources(a, b, resolutionInfoMap));
            onUpdate(resolutionInfoMap, sortedSources);
            if (!completer.isCompleted) completer.complete();
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
        );
      });

      await Future.wait(detectionCompleters.map((c) => c.future));
    } catch (e) {
      // Handle error
    } finally {
      onLoadingStateChanged(false);
      final sortedSources = List<Video>.from(videoSources)..sort((a, b) => _compareSources(a, b, resolutionInfoMap));
      onUpdate(resolutionInfoMap, sortedSources);
    }
  }

  Future<String?> _getVideoDetailForResolution(String source, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverAddress = prefs.getString('api_server_address');

      if (serverAddress == null) {
        return null;
      }

      final apiClient = ApiClient(baseUrl: serverAddress);
      final repository = MovieRepositoryImpl(
        remoteDataSource: MovieRemoteDataSourceImpl(apiClient),
      );

      final videoDetail = await repository.getVideoDetail(source, id);
      if (videoDetail.episodes != null && videoDetail.episodes!.isNotEmpty) {
        return videoDetail.episodes!.first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  int _compareSources(Video a, Video b, Map<String, VideoResolutionInfo> resolutionInfoMap) {
    final infoA = resolutionInfoMap[a.id];
    final infoB = resolutionInfoMap[b.id];

    if (infoA == null && infoB == null) return 0;
    if (infoA == null) return 1;
    if (infoB == null) return -1;

    final qualityRankA = _getQualityRank(infoA.quality);
    final qualityRankB = _getQualityRank(infoB.quality);
    if (qualityRankA != qualityRankB) {
      return qualityRankB.compareTo(qualityRankA);
    }

    final speedA = _parseSpeed(infoA.loadSpeed);
    final speedB = _parseSpeed(infoB.loadSpeed);
    if (speedA != speedB) {
      return speedB.compareTo(speedA);
    }

    return infoA.pingTime.compareTo(infoB.pingTime);
  }

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

  double _parseSpeed(String? speedString) {
    if (speedString == null ||
        speedString == 'N/A' ||
        speedString.contains('测速中') ||
        speedString.contains('错误')) {
      return 0.0;
    }
    try {
      final parts = speedString.split(' ');
      if (parts.length != 2) return 0.0;

      final value = double.tryParse(parts[0]) ?? 0.0;
      final unit = parts[1].toUpperCase();

      if (unit == 'MB/S') {
        return value * 1024;
      } else if (unit == 'KB/S') {
        return value;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}
