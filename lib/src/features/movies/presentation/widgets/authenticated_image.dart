import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

class AuthenticatedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AuthenticatedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      String imageUrl = widget.imageUrl;
      
      // 如果是豆瓣图片且不是代理URL，转换为代理URL
      if (imageUrl.contains('doubanio.com') && !imageUrl.contains('/api/image-proxy')) {
        final encodedUrl = Uri.encodeComponent(imageUrl);
        imageUrl = 'https://tv.lightndust.cn/api/image-proxy?url=$encodedUrl';
        print('Using proxy URL: $imageUrl');
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      
      // 添加认证Cookie
      final prefs = await SharedPreferences.getInstance();
      final authCookie = prefs.getString('auth_cookie');
      
      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      };
      
      if (authCookie != null && authCookie.isNotEmpty) {
        headers['Cookie'] = authCookie;
      }

      final response = await dio.get(
        imageUrl,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _imageData = Uint8List.fromList(response.data);
          _isLoading = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Image load error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _imageData == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Icon(
          Icons.movie,
          size: 48,
          color: Colors.grey,
        ),
      );
    }

    return Image.memory(
      _imageData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}