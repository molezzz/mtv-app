import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/services/auth_service.dart';

class ApiClient {
  final Dio _dio = Dio();
  final CookieJar _cookieJar = CookieJar();
  late final AuthService _authService;

  ApiClient({required String baseUrl}) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(milliseconds: 5000);
    _dio.options.receiveTimeout = const Duration(milliseconds: 3000);
    
    // 添加Cookie管理器
    _dio.interceptors.add(CookieManager(_cookieJar));
    
    // 添加认证拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 为每个请求添加保存的认证Cookie
        await _addAuthCookie(options);
        handler.next(options);
      },
    ));
    
    _dio.interceptors.add(LogInterceptor(responseBody: true)); // For debugging
    
    // 初始化认证服务
    _authService = AuthService(_dio);
  }

  Dio get dio => _dio;
  AuthService get authService => _authService;
  
  /// 为请求添加认证Cookie
  Future<void> _addAuthCookie(RequestOptions options) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authCookie = prefs.getString('auth_cookie');
      
      if (authCookie != null && authCookie.isNotEmpty) {
        // 解析Cookie并添加到请求头
        if (options.headers['cookie'] != null) {
          options.headers['cookie'] = '${options.headers['cookie']}; $authCookie';
        } else {
          options.headers['cookie'] = authCookie;
        }
      }
    } catch (e) {
      // 忽略添加Cookie错误
    }
  }
}