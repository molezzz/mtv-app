import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  group('M3U8 Parsing', () {
    test('Test regex pattern with sample M3U8 content', () {
      // 测试现有的正则表达式
      final regExp = RegExp(r'RESOLUTION=(\d+)x(\d+)');

      // 模拟一些可能的M3U8内容格式
      final sampleContents = [
        '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1500000,RESOLUTION=1280x720\nhttp://example.com/720p.m3u8',
        '#EXTM3U\n#EXT-X-STREAM-INF:RESOLUTION=1920x1080,BANDWIDTH=3000000\nhttp://example.com/1080p.m3u8',
        '#EXTM3U\n#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=240000,CODECS="mp4a.40.2, avc1.4d4015",RESOLUTION=416x234\nhttp://example.com/240p.m3u8',
      ];

      for (final content in sampleContents) {
        final match = regExp.firstMatch(content);
        if (match != null) {
          final width = int.tryParse(match.group(1) ?? '0') ?? 0;
          final height = int.tryParse(match.group(2) ?? '0') ?? 0;
          print('Matched: width=$width, height=$height');
          expect(width, greaterThan(0));
          expect(height, greaterThan(0));
        } else {
          print('No match found for content: $content');
        }
      }
    });

    test('Test with real M3U8 URL', () async {
      final dio = Dio();
      try {
        // 使用一个公开的M3U8测试URL
        final response =
            await dio.get('https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8');
        final content = response.data.toString();

        print('M3U8 Content length: ${content.length}');
        print(
            'First 500 characters: ${content.substring(0, content.length > 500 ? 500 : content.length)}');

        // 测试现有的正则表达式
        final regExp = RegExp(r'RESOLUTION=(\d+)x(\d+)');
        final match = regExp.firstMatch(content);

        if (match != null) {
          final width = int.tryParse(match.group(1) ?? '0') ?? 0;
          final height = int.tryParse(match.group(2) ?? '0') ?? 0;
          print('Matched: width=$width, height=$height');
        } else {
          print('No match found with existing regex');

          // 尝试其他可能的正则表达式
          final otherRegexes = [
            RegExp(r'RESOLUTION\s*=\s*(\d+)x(\d+)'),
            RegExp(r'(\d+)x(\d+)'),
            RegExp(r'RESOLUTION=(\d+)x(\d+)', caseSensitive: false),
          ];

          for (final regex in otherRegexes) {
            final otherMatch = regex.firstMatch(content);
            if (otherMatch != null) {
              final width = int.tryParse(otherMatch.group(1) ?? '0') ?? 0;
              final height = int.tryParse(otherMatch.group(2) ?? '0') ?? 0;
              print(
                  'Matched with alternative regex "$regex": width=$width, height=$height');
            }
          }
        }
      } catch (e) {
        print('Error fetching M3U8 content: $e');
      }
    });
  });
}
