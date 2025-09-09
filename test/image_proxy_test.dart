import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:mtv_app/src/core/services/image_proxy_service.dart';

void main() {
  // 模拟测试图片代理服务
  final mockApiClient = ApiClient(baseUrl: 'https://tv.lightndust.cn');
  final imageProxy = ImageProxyService(mockApiClient);
  
  // 测试豆瓣图片URL
  const originalUrl = 'https://img3.doubanio.com/view/photo/s_ratio_poster/public/p2921502283.jpg';
  final proxiedUrl = imageProxy.getProxiedImageUrl(originalUrl);
  
  print('Original URL: $originalUrl');
  print('Proxied URL: $proxiedUrl');
  
  // 测试非豆瓣图片URL
  const normalUrl = 'https://example.com/image.jpg';
  final normalProxied = imageProxy.getProxiedImageUrl(normalUrl);
  
  print('Normal URL: $normalUrl');
  print('Normal Proxied: $normalProxied');
}