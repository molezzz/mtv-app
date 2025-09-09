import 'package:mtv_app/src/core/api/api_client.dart';

class ImageProxyService {
  final ApiClient _apiClient;

  ImageProxyService(this._apiClient);

  /// 获取代理后的图片URL
  String getProxiedImageUrl(String originalUrl) {
    // 如果是豆瓣图片，使用代理API
    if (originalUrl.contains('doubanio.com')) {
      final encodedUrl = Uri.encodeComponent(originalUrl);
      final proxiedUrl = '${_apiClient.dio.options.baseUrl}/api/image-proxy?url=$encodedUrl';
      print('Image proxy conversion: $originalUrl -> $proxiedUrl');
      return proxiedUrl;
    }
    // 其他图片直接返回
    print('Image no proxy needed: $originalUrl');
    return originalUrl;
  }
}