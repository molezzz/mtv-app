void main() {
  final originalUrl = 'https://img3.doubanio.com/view/photo/s_ratio_poster/public/p2921502283.jpg';
  final encodedUrl = Uri.encodeComponent(originalUrl);
  final baseUrl = 'https://tv.lightndust.cn';
  final proxiedUrl = '$baseUrl/api/image-proxy?url=$encodedUrl';
  
  print('Original: $originalUrl');
  print('Encoded: $encodedUrl');
  print('Proxied: $proxiedUrl');
}