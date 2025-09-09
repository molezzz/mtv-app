import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthService {
  final Dio _dio;
  static const String _authCookieKey = 'auth_cookie';

  AuthService(this._dio);

  /// 登录
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final loginRequest = LoginRequest(
        username: username,
        password: password,
      );

      final response = await _dio.post(
        '/api/login',
        data: loginRequest.toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      // 检查响应状态
      if (response.statusCode == 200) {
        // 保存认证Cookie
        await _saveAuthCookie(response);
        
        return LoginResponse(
          success: true,
          message: 'Login successful',
          data: response.data,
        );
      } else {
        return LoginResponse(
          success: false,
          message: 'Login failed with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';
      
      if (e.response != null) {
        errorMessage = e.response?.data?['message'] ?? 'Login failed: ${e.response?.statusCode}';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout';
      } else {
        errorMessage = e.message ?? 'Unknown error';
      }
      
      return LoginResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  /// 登出
  Future<bool> logout() async {
    try {
      await _dio.post('/api/logout');
      await _clearAuthCookie();
      return true;
    } catch (e) {
      await _clearAuthCookie(); // 即使网络请求失败也清除本地Cookie
      return false;
    }
  }

  /// 检查认证状态
  Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString(_authCookieKey);
      return cookie != null && cookie.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 保存认证Cookie
  Future<void> _saveAuthCookie(Response response) async {
    try {
      final cookies = response.headers['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        // 查找auth cookie
        for (final cookie in cookies) {
          if (cookie.contains('auth=')) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_authCookieKey, cookie);
            break;
          }
        }
      }
    } catch (e) {
      // 忽略保存Cookie错误
    }
  }

  /// 清除认证Cookie
  Future<void> _clearAuthCookie() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authCookieKey);
    } catch (e) {
      // 忽略清除错误
    }
  }

  /// 获取保存的认证Cookie
  Future<String?> getAuthCookie() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authCookieKey);
    } catch (e) {
      return null;
    }
  }
}